-- XyTracker 黑名单功能模块
-- 功能：当黑名单人员或自己加入队伍时播报特定文字

-- 黑名单数据存储（SavedVariables会自动处理）
XYT_Blacklist = XYT_Blacklist or {}

-- 初始化黑名单数据
function XYT_Blacklist_Initialize()
    -- 确保黑名单数据存在并初始化默认值
    if type(XYT_Blacklist) ~= "table" then
        XYT_Blacklist = {}
    end
    
    if XYT_Blacklist.enabled == nil then
        XYT_Blacklist.enabled = true
    end
    
    if not XYT_Blacklist.blacklistedPlayers then
        XYT_Blacklist.blacklistedPlayers = {}
    end
    
    if not XYT_Blacklist.announcementText then
        XYT_Blacklist.announcementText = "★黑名单警报★ {player} 已加入队伍，请注意！"
    end
    
    -- 注册事件监听
    XYT_Blacklist_RegisterEvents()
    
    -- 添加测试数据（只在第一次加载时添加）
    if not XYT_Blacklist.initialized then
        XYT_Blacklist_AddTestData()
        XYT_Blacklist.initialized = true
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("XyTracker 黑名单功能已加载")
end

-- 添加测试数据
function XYT_Blacklist_AddTestData()
    -- 添加一些测试黑名单玩家
    XYT_Blacklist.blacklistedPlayers["测试1"] = {
        name = "测试1",
        reason = "测试原因1",
        addedBy = "系统",
        timestamp = time()
    }
    

    
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 已添加测试黑名单数据")
end

-- 注册事件监听
function XYT_Blacklist_RegisterEvents()
    -- 创建事件框架
    if not XYT_BlacklistFrame then
        XYT_BlacklistFrame = CreateFrame("Frame")
    end
    
    -- 注册队伍成员变化事件（1.12中小队/团队成员变动都触发PARTY_MEMBERS_CHANGED）
    XYT_BlacklistFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    XYT_BlacklistFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- 设置事件处理函数
    XYT_BlacklistFrame:SetScript("OnEvent", XYT_Blacklist_OnEvent)
end

-- 事件处理函数
function XYT_Blacklist_OnEvent()
    if not XYT_Blacklist.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 黑名单功能已禁用")
        return
    end
    
    if event == "PARTY_MEMBERS_CHANGED" then
        XYT_Blacklist_CheckGroupMembers()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 玩家进入世界时检查当前队伍成员
        XYT_Blacklist_CheckGroupMembers()
    end
end

-- 检查队伍成员
function XYT_Blacklist_CheckGroupMembers()
    -- 检查自己是否加入队伍
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        -- 检查队伍中是否有黑名单玩家
        XYT_Blacklist_CheckBlacklistedPlayers()
    end
end

-- 检查黑名单玩家
function XYT_Blacklist_CheckBlacklistedPlayers()
    if not XYT_Blacklist.enabled then
        return
    end
    
    -- 团队用 raid 单位，小队用 party 单位（原逻辑小队时循环上限为0，永远不检查）
    local numGroupMembers = GetNumRaidMembers()
    local unitPrefix = "raid"
    if numGroupMembers == 0 then
        numGroupMembers = GetNumPartyMembers()
        unitPrefix = "party"
    end
    
    for i = 1, numGroupMembers do
        local name = UnitName(unitPrefix .. i)
        
        if name and XYT_Blacklist.blacklistedPlayers[name] then
            -- 发现黑名单玩家，进行播报
            XYT_Blacklist_AnnounceBlacklistedPlayer(name)
        end
    end
end

-- 播报黑名单玩家
function XYT_Blacklist_AnnounceBlacklistedPlayer(playerName)
    local blacklistInfo = XYT_Blacklist.blacklistedPlayers[playerName]
    if blacklistInfo and XYT_Blacklist.announcementText then
        -- 构建包含添加者信息的播报内容
        local message = string.gsub(XYT_Blacklist.announcementText, "{player}", playerName)
        -- 添加拉黑原因信息
        local fullMessage = message .. "，拉黑原因：" .. (blacklistInfo.reason or "未知")
        -- 小队环境发 PARTY，团队发 RAID
        local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"
        SendChatMessage(fullMessage, channel)
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. fullMessage)
        
        -- 同时显示详细信息
        local details = string.format("原因：%s | 添加者：%s", 
            blacklistInfo.reason or "未知", 
            blacklistInfo.addedBy or "未知")
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 详细信息：" .. details)
    end
end

-- 添加玩家到黑名单
function XYT_Blacklist_AddPlayer(playerName, reason, addedBy)
    if not playerName or playerName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 错误：玩家名称不能为空")
        return false
    end
    
    XYT_Blacklist.blacklistedPlayers[playerName] = {
        name = playerName,
        reason = reason or "未指定原因",
        addedBy = addedBy or "未知",
        timestamp = time()
    }
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("[XyTracker] 已添加玩家 %s 到黑名单", playerName))
    return true
end

-- 从黑名单移除玩家
function XYT_Blacklist_RemovePlayer(playerName)
    if XYT_Blacklist.blacklistedPlayers[playerName] then
        XYT_Blacklist.blacklistedPlayers[playerName] = nil
        DEFAULT_CHAT_FRAME:AddMessage(string.format("[XyTracker] 已从黑名单移除玩家 %s", playerName))
        return true
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("[XyTracker] 玩家 %s 不在黑名单中", playerName))
        return false
    end
end

-- 通过序号从黑名单移除玩家
function XYT_Blacklist_RemovePlayerByIndex(index)
    index = tonumber(index)
    if not index or index < 1 then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 请输入有效的序号")
        return false
    end
    
    local count = 0
    local playerNameToRemove
    
    -- 遍历黑名单找到对应序号的玩家
    for name, _ in pairs(XYT_Blacklist.blacklistedPlayers) do
        count = count + 1
        if count == index then
            playerNameToRemove = name
            break
        end
    end
    
    if playerNameToRemove then
        return XYT_Blacklist_RemovePlayer(playerNameToRemove)
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("[XyTracker] 序号 %d 超出黑名单范围", index))
        return false
    end
end

-- 显示黑名单列表
function XYT_Blacklist_ShowList()
    local count = 0
    for name, info in pairs(XYT_Blacklist.blacklistedPlayers) do
        count = count + 1
        local details = string.format("%d. %s - 原因：%s (添加者：%s)", 
            count, name, info.reason, info.addedBy)
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. details)
    end
    
    if count == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 黑名单为空")
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("[XyTracker] 共 %d 名玩家在黑名单中", count))
    end
end

-- 启用/禁用黑名单功能
function XYT_Blacklist_SetEnabled(enabled)
    XYT_Blacklist.enabled = enabled
    local status = enabled and "启用" or "禁用"
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 黑名单功能已" .. status)
end

-- 设置播报文字
function XYT_Blacklist_SetAnnouncementText(text)
    if text and text ~= "" then
        XYT_Blacklist.announcementText = text
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 已更新黑名单播报文字")
        return true
    end
    return false
end

-- 简单的命令解析函数
local function XYT_SplitCommand(msg)
    if not msg or msg == "" then
        return ""
    end
    
    local parts = {}
    for part in string.gmatch(msg, "%S+") do
        table.insert(parts, part)
    end
    
    return parts[1] or "", parts[2] or "", parts[3] or "", parts[4] or ""
end

-- 命令行接口函数
function XYT_Blacklist_CommandHandler(msg)
    local command, param1, param2, param3 = XYT_SplitCommand(msg)
    
    if command == "add" then
        if param1 then
            XYT_Blacklist_AddPlayer(param1, param2, param3)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 用法：/xyblacklist add 玩家名 [原因] [添加者]")
        end
    elseif command == "remove" then
        if param1 then
            -- 检查是否为数字序号
            if tonumber(param1) then
                XYT_Blacklist_RemovePlayerByIndex(param1)
            else
                XYT_Blacklist_RemovePlayer(param1)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 用法：/xyblacklist remove [玩家名/序号]")
        end
    elseif command == "list" then
        XYT_Blacklist_ShowList()
    elseif command == "enable" then
        XYT_Blacklist_SetEnabled(true)
    elseif command == "disable" then
        XYT_Blacklist_SetEnabled(false)
    elseif command == "settext" then
        if param1 then
            XYT_Blacklist_SetAnnouncementText(param1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 用法：/xyblacklist settext 播报文字（可使用{player}占位符）")
        end
    elseif command == "config" or command == "gui" or command == "" then
        -- 打开配置界面
        if XYT_Blacklist_ShowConfig then
            XYT_Blacklist_ShowConfig()
        else
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 配置界面功能未加载，请检查插件文件")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 黑名单功能命令：")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb config - 打开黑名单配置界面")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb add 玩家名 [原因] [添加者] - 添加玩家到黑名单")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb remove 玩家名 - 从黑名单移除玩家")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb list - 显示黑名单列表")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb enable - 启用黑名单功能")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb disable - 禁用黑名单功能")
        DEFAULT_CHAT_FRAME:AddMessage("  /xyb settext 文字 - 设置黑名单播报文字")
    end
end

-- 注册斜杠命令
SLASH_XYBLACKLIST1 = "/xyb"
SlashCmdList["XYBLACKLIST"] = XYT_Blacklist_CommandHandler

-- 插件加载时初始化
local function OnAddonLoaded()
    XYT_Blacklist_Initialize()
end

-- 注册插件加载事件
local blacklistFrame = CreateFrame("Frame")
blacklistFrame:RegisterEvent("ADDON_LOADED")
blacklistFrame:SetScript("OnEvent", function(self, event, addonName)
    if arg1 == "XyTracker" then
        OnAddonLoaded()
    end
end)

-- 导出函数供其他模块使用
XyTracker_Blacklist = {
    Initialize = XYT_Blacklist_Initialize,
    AddPlayer = XYT_Blacklist_AddPlayer,
    RemovePlayer = XYT_Blacklist_RemovePlayer,
    ShowList = XYT_Blacklist_ShowList,
    SetEnabled = XYT_Blacklist_SetEnabled,
    SetAnnouncementText = XYT_Blacklist_SetAnnouncementText
}