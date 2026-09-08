local XYT_BACKUP_POLL_INTERVAL = 5      -- 轮询间隔（秒）
local XYT_BACKUP_NOTIFY_COOLDOWN = 600  -- 自动备份提示冷却（秒），备份本身每次都执行
local XYT_BACKUP_MAX_SEARCH_DAYS = 60   -- 恢复时向前检索的天数
local XYT_BACKUP_LOSS_WINDOW = 43200    -- 登录丢失检测只关心12小时内的快照

-- 会话内状态（无需存盘）
XyTrackerBackup = {
    elapsed = 0,
    lastSnapshotMarker = 0,   -- 已处理的变更标记
    lastNotifyTime = 0,       -- 上次自动备份提示时间（time()）
    lastErrorNotifyTime = 0,  -- 上次备份失败提示时间（time()）
    loginChecked = false,     -- 登录丢失检测每会话只做一次
    restoringFromFile = false,-- 恢复重入保护（防止 XyTracker_RestoreWishList 递归）
    activityFile = nil,       -- 当前活动的数据文件名（本场活动内固定）
    lastLeaderName = "",      -- 上次检测到的许愿团长，用于划分活动
}

local function XyTracker_Backup_Msg(msg, r, g, b)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc[XyTracker]|r " .. msg, r, g, b)
end

local function XyTracker_Backup_HasSuperWoW()
    return SUPERWOW_STRING and ExportFile and ImportFile
end

------------------------------------------------------------
-- 文件名构造（与 ADKP 同风格，XY 前缀）
------------------------------------------------------------

-- 服务器名去空格；角色名空格替换为横线；同时去掉 Windows 文件名非法字符，防止 ExportFile 创建文件失败
local function XyTracker_Backup_CleanServerName(name)
    name = string.gsub(name or "", "%s", "")
    return string.gsub(name, "[\\/:%*%?\"<>|%c]", "")
end

local function XyTracker_Backup_CleanCharName(name)
    name = string.gsub(name or "", "%s", "-")
    return string.gsub(name, "[\\/:%*%?\"<>|%c]", "")
end

-- 写文件并捕获失败：Imports目录不存在/无写权限/文件名非法时，SuperWoW的ExportFile会直接抛Lua错误
local function XyTracker_Backup_SafeExport(fileName, content)
    local ok = pcall(ExportFile, fileName, content)
    return ok
end

-- 数据文件名：XYD-<服务器>-<角色>-<YYYY-MM-DD>（一天一个文件，重复备份覆盖同名文件）
local function XyTracker_Backup_BuildDataFileName(serverName, charName, dateStr)
    return "XYD-" .. serverName .. "-" .. charName .. "-" .. (dateStr or date("%Y-%m-%d"))
end

-- 固定指针文件名：XYP-<服务器>-<角色>（每个角色永远只有一个，指向当前活动的数据文件）
local function XyTracker_Backup_BuildSessionPointerName(serverName, charName)
    return "XYP-" .. serverName .. "-" .. charName
end

-- 取当前备份应写入的数据文件名，并按许愿会话划分"活动"：
-- 许愿团长由空变为某人（团长点开始许愿/团员收到XY_START）即开始一场新活动，
-- 换用新的数据文件名并重写固定指针文件；同一活动内重复备份覆盖同一文件。
-- 没有活动（或无会话）时退回按天命名的文件。
local function XyTracker_Backup_GetActivityFile(serverName, charName, currentDate)
    local leader = ""
    if XyTracker_GetLeaderName then
        leader = XyTracker_GetLeaderName() or ""
    end
    if leader == "" then
        -- 无许愿会话：清除团长标记，下次开始时（即使同一团长）也算一场新活动
        XyTrackerBackup.lastLeaderName = ""
    elseif leader ~= XyTrackerBackup.lastLeaderName then
        XyTrackerBackup.lastLeaderName = leader
        XyTrackerBackup.activityFile = "XYD-" .. serverName .. "-" .. charName .. "-" .. date("%Y-%m-%d-%H%M%S")
        XyTracker_Backup_SafeExport(XyTracker_Backup_BuildSessionPointerName(serverName, charName), XyTrackerBackup.activityFile)
    end
    return XyTrackerBackup.activityFile or XyTracker_Backup_BuildDataFileName(serverName, charName, currentDate)
end

-- 文件是否存在（SuperWoW 可能自动补 .txt 后缀）
local function XyTracker_Backup_FileExists(name)
    if ImportFile(name) then
        return true, name
    end
    local txtName = name .. ".txt"
    if ImportFile(txtName) then
        return true, txtName
    end
    return false, nil
end

------------------------------------------------------------
-- CSV 构建与解析
-- 格式：表头"名字,职业,分数,许愿"，每成员一行；字段内逗号转义为 ~~
------------------------------------------------------------

local function XyTracker_Backup_Escape(text)
    return string.gsub(tostring(text or ""), ",", "~~")
end

local function XyTracker_Backup_Unescape(text)
    return string.gsub(tostring(text or ""), "~~", ",")
end

local function XyTracker_Backup_SplitString(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

local function XyTracker_Backup_BuildCSV()
    local parts = { "名字,职业,分数,许愿" }
    if XyArray and type(XyArray) == "table" then
        for i = 1, table.getn(XyArray) do
            local info = XyArray[i]
            if info and type(info) == "table" and info.name and info.name ~= "" then
                local line = XyTracker_Backup_Escape(info.name) .. ","
                    .. XyTracker_Backup_Escape(info.class or "") .. ","
                    .. XyTracker_Backup_Escape(tostring(info.dkp or "0")) .. ","
                    .. XyTracker_Backup_Escape(info.xy or "")
                table.insert(parts, line)
            end
        end
    end
    return table.concat(parts, "\n")
end

------------------------------------------------------------
-- 备份到 Imports 目录
-- silent=true 为自动备份：提示受冷却限制，不刷屏
------------------------------------------------------------

function XyTracker_Backup_ToFile(silent)
    if not XyTracker_Backup_HasSuperWoW() then
        if not silent then
            XyTracker_Backup_Msg("错误：文件备份需要 SuperWoW 支持且 ExportFile 函数可用", 1, 0.3, 0.3)
        end
        return false
    end
    if not XyArray or type(XyArray) ~= "table" or table.getn(XyArray) == 0 then
        if not silent then
            XyTracker_Backup_Msg("许愿列表为空，无需备份", 1, 0.8, 0)
        end
        return false
    end

    local serverName = XyTracker_Backup_CleanServerName(GetRealmName() or "未知服务器")
    local charName = XyTracker_Backup_CleanCharName(UnitName("player") or "未知角色")
    local currentDate = date("%Y-%m-%d")

    -- 1. 写数据文件（一场活动一个文件，活动内重复备份覆盖同名文件；固定指针由活动划分函数维护）
    local dataFileName = XyTracker_Backup_GetActivityFile(serverName, charName, currentDate)
    if not XyTracker_Backup_SafeExport(dataFileName, XyTracker_Backup_BuildCSV()) then
        if not silent then
            XyTracker_Backup_Msg("备份失败：无法写入文件 " .. dataFileName .. ".txt（请检查游戏主目录下 Imports 文件夹是否存在、是否有写权限）", 1, 0.3, 0.3)
        else
            local now = time()
            if now - XyTrackerBackup.lastErrorNotifyTime >= XYT_BACKUP_NOTIFY_COOLDOWN then
                XyTrackerBackup.lastErrorNotifyTime = now
                XyTracker_Backup_Msg("自动备份失败：无法写入 Imports 目录（请检查 Imports 文件夹是否存在、是否有写权限）", 1, 0.3, 0.3)
            end
        end
        return false
    end

    -- 2. 提示（自动备份受冷却限制，避免刷屏）
    if silent then
        local now = time()
        if now - XyTrackerBackup.lastNotifyTime >= XYT_BACKUP_NOTIFY_COOLDOWN then
            XyTracker_Backup_Msg("许愿数据发生变动，已自动备份到 Imports 目录")
            XyTrackerBackup.lastNotifyTime = now
        end
    else
        XyTracker_Backup_Msg("许愿数据已备份到: " .. dataFileName, 0.3, 1, 0.3)
    end
    return true
end

-- 手动备份（/xy backup）：内存快照 + 文件备份
function XyTracker_Backup_ForceSave()
    XyTracker_SaveWishList(true)
    XyTrackerBackup.lastSnapshotMarker = _G["XyTracker_SavedWishList_LastUpdate"] or time()
    if XyTracker_Backup_HasSuperWoW() then
        XyTracker_Backup_ToFile(false)
    else
        XyTracker_Backup_Msg("未检测到 SuperWoW，已仅保存到 SavedVariables 快照（正常退出时生效）", 1, 0.8, 0)
    end
end

------------------------------------------------------------
-- 从 Imports 目录恢复
-- 成功返回 true；无 SuperWoW / 找不到备份 / 内容无效返回 false（调用方回退到 SV 快照）
------------------------------------------------------------

function XyTracker_Backup_RestoreFromFile()
    if not XyTracker_Backup_HasSuperWoW() then
        return false
    end

    local serverName = XyTracker_Backup_CleanServerName(GetRealmName() or "未知服务器")
    local charName = XyTracker_Backup_CleanCharName(UnitName("player") or "未知角色")

    -- 1. 固定指针文件 -> 当前活动的数据文件（崩溃后 SV 未落盘也能找到最新备份）
    local dataFileName = nil
    local content = nil
    local foundDate = nil
    local sessionPointer = XyTracker_Backup_BuildSessionPointerName(serverName, charName)
    local pointerTarget = ImportFile(sessionPointer) or ImportFile(sessionPointer .. ".txt")
    if pointerTarget and pointerTarget ~= "" then
        pointerTarget = string.gsub(pointerTarget, "[\r\n]", "")
        pointerTarget = string.gsub(pointerTarget, "^%s*(.-)%s*$", "%1")
        local c = ImportFile(pointerTarget) or ImportFile(pointerTarget .. ".txt")
        if c and c ~= "" then
            dataFileName = pointerTarget
            content = c
            foundDate = string.match(dataFileName, "(%d%d%d%d%-%d%d%-%d%d)") or ""
        end
    end

    -- 2. 按天的数据文件（无许愿会话期间的备份），从今天起逐日倒退检索
    if not content then
        for i = 0, XYT_BACKUP_MAX_SEARCH_DAYS - 1 do
            local checkDate = date("%Y-%m-%d", time() - i * 24 * 3600)
            local candidate = XyTracker_Backup_BuildDataFileName(serverName, charName, checkDate)
            local c = ImportFile(candidate) or ImportFile(candidate .. ".txt")
            if c and c ~= "" then
                dataFileName = candidate
                content = c
                foundDate = checkDate
                break
            end
        end
    end

    if not content or content == "" then
        return false  -- 静默返回，由调用方回退到 SavedVariables 快照
    end

    -- 3. 解析 CSV（跳过表头），组装成 SavedWishList 形状
    local normalizedData = string.gsub(content, "\r\n", "\n")
    normalizedData = string.gsub(normalizedData, "\r", "\n")
    local lines = XyTracker_Backup_SplitString(normalizedData, "\n")

    local members = {}
    for i, line in ipairs(lines) do
        if line ~= "" and i > 1 then
            local fields = XyTracker_Backup_SplitString(line, ",")
            if table.getn(fields) >= 4 then
                local name = XyTracker_Backup_Unescape(fields[1])
                if name ~= "" then
                    table.insert(members, {
                        name = name,
                        class = XyTracker_Backup_Unescape(fields[2]),
                        dkp = XyTracker_Backup_Unescape(fields[3]),
                        xy = XyTracker_Backup_Unescape(fields[4]),
                    })
                end
            end
        end
    end

    if table.getn(members) == 0 then
        XyTracker_Backup_Msg("备份文件中没有有效的许愿数据：" .. dataFileName .. "，尝试从 SavedVariables 快照恢复", 1, 0.8, 0)
        return false
    end

    -- 6. 写入 SavedWishList，复用现有恢复逻辑合并进 XyArray（重入保护）
    local saved = {}
    saved.version = "file-1.0"
    saved.saveTime = time()
    for i, m in ipairs(members) do
        table.insert(saved, m)
    end
    _G["SavedWishList"] = saved

    XyTrackerBackup.restoringFromFile = true
    XyTracker_RestoreWishList()
    XyTrackerBackup.restoringFromFile = false
    XyTracker_UpdateList()

    XyTracker_Backup_Msg("已从 Imports 备份恢复 " .. table.getn(members) ..
        " 条许愿数据（" .. foundDate .. "，文件：" .. dataFileName .. "）", 0.3, 1, 0.3)
    return true
end

------------------------------------------------------------
-- 登录丢失检测
------------------------------------------------------------

local function XyTracker_Backup_CheckDataLoss()
    if XyTrackerBackup.loginChecked then return end
    XyTrackerBackup.loginChecked = true

    local xyCount = 0
    if XyArray and type(XyArray) == "table" then
        xyCount = table.getn(XyArray)
    end
    if xyCount > 0 then return end

    -- 线索1：SavedVariables 里有较新的快照（12小时内、至少3条）
    local hint = false
    if SavedWishList and type(SavedWishList) == "table" then
        local savedCount = 0
        for k, v in pairs(SavedWishList) do
            if type(k) == "number" then
                savedCount = savedCount + 1
            end
        end
        if savedCount >= 3 and time() - (SavedWishList.saveTime or 0) < XYT_BACKUP_LOSS_WINDOW then
            hint = true
        end
    end

    -- 线索2：Imports 目录里有文件备份（固定指针，或今天/昨天的按天数据文件）
    if not hint and XyTracker_Backup_HasSuperWoW() then
        local serverName = XyTracker_Backup_CleanServerName(GetRealmName() or "")
        local charName = XyTracker_Backup_CleanCharName(UnitName("player") or "")
        local exists = XyTracker_Backup_FileExists(
            XyTracker_Backup_BuildSessionPointerName(serverName, charName))
        if not exists then
            for i = 0, 1 do
                local checkDate = date("%Y-%m-%d", time() - i * 24 * 3600)
                exists = XyTracker_Backup_FileExists(
                    XyTracker_Backup_BuildDataFileName(serverName, charName, checkDate))
                if exists then break end
            end
        end
        if exists then
            hint = true
        end
    end

    if hint then
        XyTracker_Backup_Msg("检测到许愿列表为空，但存在可用备份。点\"恢复许愿\"按钮或输入 |cffffff00/xy restore|r 恢复", 1, 0.3, 0.3)
    end
end

------------------------------------------------------------
-- 轮询：数据变动 -> 内存快照 + 文件自动备份
------------------------------------------------------------

local function XyTracker_Backup_Poll()
    local marker = _G["XyTracker_SavedWishList_LastUpdate"] or 0
    if marker <= XyTrackerBackup.lastSnapshotMarker then
        return
    end

    -- 内存快照（无 SuperWoW 时的兜底，正常退出时随 SavedVariables 落盘）
    XyTracker_SaveWishList(true)
    XyTrackerBackup.lastSnapshotMarker = marker

    -- 文件自动备份（需 SuperWoW，崩溃也不丢）
    local autoEnabled = not XyTrackerOptions or XyTrackerOptions.WishAutoBackupEnabled ~= false
    if autoEnabled and XyTracker_Backup_HasSuperWoW() then
        XyTracker_Backup_ToFile(true)
    end
end

------------------------------------------------------------
-- 事件与轮询框架
------------------------------------------------------------

local XyTrackerBackupFrame = CreateFrame("Frame", "XyTrackerBackupFrame")
XyTrackerBackupFrame:RegisterEvent("VARIABLES_LOADED")
XyTrackerBackupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

XyTrackerBackupFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if not XyTrackerOptions then XyTrackerOptions = {} end
        if XyTrackerOptions.WishAutoBackupEnabled == nil then
            XyTrackerOptions.WishAutoBackupEnabled = true
        end
        XyTrackerBackup.lastSnapshotMarker = _G["XyTracker_SavedWishList_LastUpdate"] or 0
    elseif event == "PLAYER_ENTERING_WORLD" then
        XyTracker_Backup_CheckDataLoss()
    end
end)

XyTrackerBackupFrame:SetScript("OnUpdate", function()
    XyTrackerBackup.elapsed = XyTrackerBackup.elapsed + (arg1 or 0)
    if XyTrackerBackup.elapsed < XYT_BACKUP_POLL_INTERVAL then
        return
    end
    XyTrackerBackup.elapsed = 0

    XyTracker_Backup_Poll()
end)
