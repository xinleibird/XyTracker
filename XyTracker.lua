if not string.match then
    string.match = function(text, pattern, init)
        local startPos, endPos, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9 = string.find(text, pattern, init)
        if not startPos then
            return nil
        end
        if cap1 ~= nil then
            return cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9
        end
        return string.sub(text, startPos, endPos)
    end
end

if not string.gmatch and string.gfind then
    string.gmatch = string.gfind
end

if not math.fmod and math.mod then
    math.fmod = math.mod
end

if not table.insert and tinsert then
    table.insert = tinsert
end

if not table.remove and tremove then
    table.remove = tremove
end

-- 全局变量定义
-- 快捷键分类标题
BINDING_HEADER_XYTRACKER = "|cffFF0000----许愿团快捷键----|r"
local XyInProgress, NewDKP, IsLeader, NoXyList = false
local Xys = 0 -- 单独初始化Xys变量为0，避免nil值错误
local LeaderName = ""  -- 存储许愿权限拥有者名称
DefaultDKP = 4  -- 初始化DefaultDKP变量，避免nil值错误

-- 统一的XyTrackerOptions初始化函数
function InitializeXyTrackerOptions()
    -- 确保XyTrackerOptions表存在
    if not XyTrackerOptions then
        XyTrackerOptions = {}
    end
    
    -- 初始化QualityFilters（物品品质筛选设置）
    if not XyTrackerOptions.QualityFilters then
        XyTrackerOptions.QualityFilters = {
            [5] = true,  -- 橙色(传说)
            [4] = true,  -- 紫色(史诗)
            [3] = false, -- 蓝色(精良)
            [2] = false, -- 绿色(优秀)
            [1] = false, -- 白色(普通)
            [0] = false  -- 灰色(粗糙)
        }
    end
    
    -- 初始化宣言设置
    if not XyTrackerOptions.Declaration then
        XyTrackerOptions.Declaration = ""
    end
    
    -- 初始化欢迎文本设置
    if not XyTrackerOptions.CustomStarttext then
        XyTrackerOptions.CustomStarttext = nil  -- 使用默认值
    end
    
    -- 初始化DKP和Roll相关的时间设置
    -- 初始化其他设置
    if XyTrackerOptions.AutoAnnounce == nil then
        XyTrackerOptions.AutoAnnounce = true  -- 默认开启许愿重复警报及自动查询
    end
    
    if XyTrackerOptions.greenModeEnabled == nil then
        XyTrackerOptions.greenModeEnabled = false
    end
    
    if XyTrackerOptions.blueModeEnabled == nil then
        XyTrackerOptions.blueModeEnabled = false
    end
    
    if XyTrackerOptions.purpleModeEnabled == nil then
        XyTrackerOptions.purpleModeEnabled = true  -- 默认紫色开启
    end
    
    if XyTrackerOptions.XyOnlyMode == nil then
        XyTrackerOptions.XyOnlyMode = 0
    end
    
    if XyTrackerOptions.autoMinDkp == nil then
        XyTrackerOptions.autoMinDkp = true  -- 默认开启自动扣分
    end

    if XyTrackerOptions.HideLeftMembers == nil then
        XyTrackerOptions.HideLeftMembers = true  -- 默认勾选隐藏离队人员（不勾选则离队人员灰色显示）
    end
end


-- 延迟调用函数


-- 确保快捷键函数在全局作用域中可用
_G["XyTracker_Toggle"] = XyTracker_Toggle

-- 切换XyTracker窗口显示状态的函数
function XyTracker_Toggle()
    if getglobal("XyTrackerFrame") then
        if getglobal("XyTrackerFrame"):IsVisible() then
            getglobal("XyTrackerFrame"):Hide()
        else
            getglobal("XyTrackerFrame"):Show()
        end
    end
end

local XyDelayFrame = nil
local XyDelayQueue = {}
function XyTracker_DelayCall(func, delay)
    table.insert(XyDelayQueue, {func = func, remaining = delay})
    if not XyDelayFrame then
        XyDelayFrame = CreateFrame("Frame")
        XyDelayFrame:SetScript("OnUpdate", function()
            if table.getn(XyDelayQueue) == 0 then return end
            local elapsed = arg1 or 0
            local i = 1
            while i <= table.getn(XyDelayQueue) do
                local task = XyDelayQueue[i]
                task.remaining = task.remaining - elapsed
                if task.remaining <= 0 then
                    table.remove(XyDelayQueue, i)
                    task.func()
                else
                    i = i + 1
                end
            end
        end)
    end
end


local raidMessages = {}
local tempDeductedPoints = nil








local XyItemCount = {}  -- 新增：用于记录物品许愿次数
LootList = {}  -- 存储拾取列表数据（全局变量，用于保存）
LootSortField = "itemName"  -- 默认排序字段（改为全局变量）
LootSortOrder = 1  -- 1为升序，-1为降序（改为全局变量）
XY_BUTTON_HEIGHT = 25;
Xy_SortOptions = { ["method"] = "", ["itemway"] = "" };
UnitPopupButtons["GET_XY"] = { text = "查询许愿", dist = 0 };
-- 同步控制变量
local lastAutoSyncTime = nil  -- 上次自动同步时间（团长用）
local lastSyncRequestTime = nil  -- 上次请求同步时间（团员用）
-- 已移除加减分数按钮
UnitPopupButtons["ADD_DKP"] = { text = "增加分数", dist = 0, nested = 1 };
UnitPopupButtons["Minus_DKP"] = { text = "扣除分数", dist = 0, nested = 1 };


-- 已移除加减分数子菜单按钮
UnitPopupButtons["ADD_DKP_1"] = { text = "增加1分", dist = 0 };
UnitPopupButtons["ADD_DKP_2"] = { text = "增加2分", dist = 0 };
UnitPopupButtons["ADD_DKP_3"] = { text = "增加3分", dist = 0 };
UnitPopupButtons["ADD_DKP_4"] = { text = "增加4分", dist = 0 };
UnitPopupButtons["MINUS_DKP_1"] = { text = "扣除1分", dist = 0 };
UnitPopupButtons["MINUS_DKP_2"] = { text = "扣除2分", dist = 0 };
UnitPopupButtons["MINUS_DKP_3"] = { text = "扣除3分", dist = 0 };
UnitPopupButtons["MINUS_DKP_4"] = { text = "扣除4分", dist = 0 };


NewDKP = false

-- 宣言相关变量
local playerDeclaration = ""

-- 宣言功能函数
function XyTracker_OnDeclarationButtonClick()
    -- 打开独立宣言窗口
    local declarationWindow = getglobal("XyTrackerDeclarationFrame")
    local declarationEditBox = getglobal("XyTrackerDeclarationLargeEditBox")
    
    -- 确保宣言内容正确加载，优先使用XyTrackerOptions中的值
    if XyTrackerOptions and XyTrackerOptions.Declaration and XyTrackerOptions.Declaration ~= "" then
        declarationEditBox:SetText(XyTrackerOptions.Declaration)
    elseif playerDeclaration and playerDeclaration ~= "" then
        declarationEditBox:SetText(playerDeclaration)
    else
        declarationEditBox:SetText("")
    end
    
    declarationEditBox:SetFocus()
    
    -- 显示窗口
    declarationWindow:Show()
    
    -- 已移除调试信息
end

-- 保存宣言内容的函数
function XyTracker_SaveDeclaration()
    local declarationEditBox = getglobal("XyTrackerDeclarationLargeEditBox")
    local declarationWindow = getglobal("XyTrackerDeclarationFrame")
    
    -- 获取输入框中的内容
    local newDeclaration = declarationEditBox:GetText()
    
    -- 确保保存宣言内容到两个变量，确保通告功能能够正确读取
    playerDeclaration = newDeclaration
    
    -- 持久化保存到设置中，下次开团时自动加载
 InitializeXyTrackerOptions()
   DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 宣言文本已更新并保存")

 XyTrackerOptions.Declaration = newDeclaration
    
    -- 已移除确认消息和调试信息
    
    -- 隐藏窗口
    declarationWindow:Hide()
end

function XyTracker_OnAnnounceDeclarationButtonClick()
    -- 优先从XyTrackerOptions获取宣言内容，确保使用最新保存的值
    local declarationText = XyTrackerOptions and XyTrackerOptions.Declaration or playerDeclaration

    -- 播报频道：自己是团队团长或助理时用团队警告（醒目），否则回退普通团队频道
    -- （RAID_WARNING 需要职务，非团长/助理发送会被客户端拒发）
    local announceChannel = "RAID"
    if IsRaidLeader() or IsRaidOfficer() then
        announceChannel = "RAID_WARNING"
    end

    if declarationText and declarationText ~= "" then
        local lineCount = 0
        local startPos = 1
        local textLength = string.len(declarationText)
        
        while startPos <= textLength do
            -- 查找下一个换行符或字符串结束位置
            local endPos = string.find(declarationText, "\n", startPos)
            if not endPos then
                endPos = textLength + 1
            end
            
            -- 提取当前行文本
            local line = string.sub(declarationText, startPos, endPos - 1)
            if line and line ~= "" then
                lineCount = lineCount + 1
                if lineCount == 1 then
                    -- 第一行添加前缀
                    SendChatMessage("【团队宣言】" .. line, announceChannel, nil, nil)
                else
                    -- 后续行直接发送
                    SendChatMessage(line, announceChannel, nil, nil)
                end
            end
            
            -- 移动到下一行起始位置
            startPos = endPos + 1
        end
        
        -- 已移除确认消息
    else
        -- 已移除提示消息
    end
end





-- 玩家发言记录已在文件头部统一声明（见出分拍卖相关变量处，此处原 local 声明已移除避免遮蔽）
--自动扣分开关
function autoMin_OnClick()
    XyTrackerOptions.autoMinDkp = this:GetChecked()
end
-- 添加颜色模式切换函数
function greenMode_OnClick()
    XyTrackerOptions.greenModeEnabled = this:GetChecked()
end

function blueMode_OnClick()
    XyTrackerOptions.blueModeEnabled = this:GetChecked()
end

function purpleMode_OnClick()
    XyTrackerOptions.purpleModeEnabled = this:GetChecked()
end

function autoMode_OnClick()
    if this:GetChecked() then
        XyTrackerOptions.XyOnlyMode = 1
    else
        XyTrackerOptions.XyOnlyMode = 0
    end
end

function autoAnnounce_OnClick()
    if this:GetChecked() then
        XyTrackerOptions.AutoAnnounce = true
    else
        XyTrackerOptions.AutoAnnounce = false
    end
end

function autoBackup_OnClick()
    XyTrackerOptions.WishAutoBackupEnabled = this:GetChecked() and true or false
end

-- 隐藏离队人员开关：勾选隐藏离队人员，不勾选则离队人员灰色显示，切换后立即刷新列表
function hideLeft_OnClick()
    XyTrackerOptions.HideLeftMembers = this:GetChecked() and true or false
    XyTracker_UpdateList()
end

-- 调用默认DKP
function printDefaultDKP()
    getglobal("allDKPFrameTXT"):SetText(DefaultDKP);
end
-- 更新默认DKP
function NEWDefaultDKP()
    DefaultDKP = getglobal("allDKPFrameTXT"):GetNumber();
    NewDKP = true
    XyTracker_OnRefreshButtonClick()
    XyTracker_UpdateList() -- 更新DKP列表
    SendChatMessage("通知：当前默认DKP为每人" .. DefaultDKP .. "分，分数已初始化", "RAID", this.language, nil)
end
-- 检查列表中是否包含指定元素
function contain(v, l)
    if not l then
        return false
    end
    local n = table.getn(l)
    if n > 0 then
        for i = 1, n do
            local lv = l[i]
            if v == lv then
                return true
            end
        end
    end


    return false
end
-- 注册右键菜单权限控制按钮
function XyTracker_RegisterRightClickMenuButtons()
    if UnitPopupMenus["PARTY"] then
        if IsLeader then
            if not contain("ADD_DKP", UnitPopupMenus["PARTY"]) then
                table.insert(UnitPopupMenus["PARTY"], "ADD_DKP")
            end
            if not contain("Minus_DKP", UnitPopupMenus["PARTY"]) then
                table.insert(UnitPopupMenus["PARTY"], "Minus_DKP")
            end
            -- -- 已移除：添加ROLL点拍卖按钮（仅团长可见）
            -- if not contain("ROLL_AUCTION", UnitPopupMenus["PARTY"]) then
            --     table.insert(UnitPopupMenus["PARTY"], "ROLL_AUCTION")
            -- end
        else
            -- 如果不是团长，移除这些按钮
            local index1 = nil
            local index2 = nil
            -- local index3 = nil  -- 已移除：ROLL点拍卖按钮索引
            for i, v in ipairs(UnitPopupMenus["PARTY"]) do
                if v == "ADD_DKP" then
                    index1 = i
                elseif v == "Minus_DKP" then
                    index2 = i
                -- elseif v == "ROLL_AUCTION" then  -- 已移除：查找ROLL点拍卖按钮
                --     index3 = i
                end
            end
            if index1 then
                table.remove(UnitPopupMenus["PARTY"], index1)
            end
            if index2 then
                table.remove(UnitPopupMenus["PARTY"], index2)
            end
            -- if index3 then  -- 已移除：移除ROLL点拍卖按钮
            --     table.remove(UnitPopupMenus["PARTY"], index3)
            -- end
        end
        if not contain("GET_XY", UnitPopupMenus["PARTY"]) then
            table.insert(UnitPopupMenus["PARTY"], "GET_XY")
        end
    end
end

-- 发送所有人的许愿
function XyTracker_AnnounceAllWishes()
    local n = table.getn(XyArray)
    if n > 0 then
        for i = 1, n do
            local info = XyArray[i]
            local name = info["name"]
            local xy = info["xy"] or "---未许愿---"
            if xy ~= "---未许愿---" and xy ~= "" then
                SendChatMessage(name .. " 许愿：" .. xy, "RAID", this.language, nil)
            end
        end
    end
end

-- 全局安全字符串清理函数

function safeCleanString(str)
    if not str or type(str) ~= "string" then
        return ""
    end

    local cleanStr = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
    cleanStr = string.gsub(cleanStr, "|r", "")
    
    -- 移除空格和特殊字符
    cleanStr = string.gsub(cleanStr, "%s+", "")
    cleanStr = string.lower(cleanStr)
    
    return cleanStr
end
-- 插件加载时的初始化函数
function XyTracker_OnLoad()
    -- 初始化IsLeader变量
    IsLeader = false
    
    -- 初始化拾取列表排序变量
    LootSortField = "timestamp" -- 默认按拾取时间排序
    LootSortOrder = 1 -- 默认升序（1表示升序，-1表示降序）
    
    -- 在单位弹出菜单中添加按钮
    XyTracker_RegisterRightClickMenuButtons()
    
    -- 初始化LootList为空表（如果不存在）
    if LootList == nil then
        LootList = {}
    end
    
    -- 初始化SavedLootList为空表（如果不存在）
    if SavedLootList == nil then
        SavedLootList = {}
    end
    
    -- 初始化SavedWishList为空表（如果不存在）
    if SavedWishList == nil then
        SavedWishList = {}
    end
    
    -- 初始化许愿分设置
    if not XyTrackerOptions then XyTrackerOptions = {} end
    
    -- 加载保存的宣言内容 - 增强版，确保内容能够正确加载
    if XyTrackerOptions and XyTrackerOptions.Declaration and XyTrackerOptions.Declaration ~= "" then
        playerDeclaration = XyTrackerOptions.Declaration
    -- 否则回退到旧的存储方式
    elseif XyTrackerDeclaration and XyTrackerDeclaration ~= "" then
        playerDeclaration = XyTrackerDeclaration
    else
        -- 初始化默认宣言内容
        playerDeclaration = " 参与本次副本必须同意以下副本规则，参与活动表示接受：\n 1.本次副本内装备分配以许愿为准。\n 2.中途跳车自愿接受封禁30天规则。\n 3.所有事宜最终解释权归团长所有。"
        InitializeXyTrackerOptions()
        XyTrackerOptions.Declaration = playerDeclaration
    end
    
    -- 已移除加载记录调试信息

    -- 设置命令行指令
    SlashCmdList["XYTRACKER"] = XyTracker_OnSlashCommand
    SLASH_XYTRACKER1 = "/xyt"
    SLASH_XYTRACKER2 = "/Xytrack"
    SLASH_XYTRACKER3 = "/xy"
    -- 注册事件监听
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("CHAT_MSG_SYSTEM")
    this:RegisterEvent("CHAT_MSG_RAID")
    this:RegisterEvent("CHAT_MSG_RAID_LEADER")
    this:RegisterEvent("CHAT_MSG_RAID_WARNING")
    this:RegisterEvent("CHAT_MSG_ADDON")
    this:RegisterEvent("CHAT_MSG_WHISPER")
    this:RegisterEvent("PLAYER_LOGOUT")
    this:RegisterEvent("CHAT_MSG_LOOT")
    this:RegisterEvent("PLAYER_ENTERING_WORLD")
    this:RegisterEvent("RAID_ROSTER_UPDATE")
    
    -- 窗口颜色和拖动功能已在XML中设置，避免重复设置导致冲突
    -- 备份原始单位弹出窗口点击处理函数
    ori_unitpopup1 = UnitPopup_OnClick;
    -- 替换单位弹出窗口点击处理函数
    UnitPopup_OnClick = ple_unitpopup1;
    -- 初始化变量
    InitializeXyTrackerOptions()
    if XyArray == nil then
        XyArray = {}
    end
    XyInProgress = false
    NoXyList = ""
    Xys = 0
    -- 用于控制接收同步数据时不发送公告
    IsReceivingSync = false


    local cb
    cb = getglobal("autoModeButtons");    if cb then cb:SetChecked(XyTrackerOptions.XyOnlyMode == 1) end
    cb = getglobal("autoAnnounceButton"); if cb then cb:SetChecked(XyTrackerOptions.AutoAnnounce and true or false) end
    cb = getglobal("autoBackupButton");    if cb then cb:SetChecked(XyTrackerOptions.WishAutoBackupEnabled ~= false) end
    cb = getglobal("autoMinButtons");     if cb then cb:SetChecked(XyTrackerOptions.autoMinDkp and true or false) end
    cb = getglobal("greenModeButtons");   if cb then cb:SetChecked(XyTrackerOptions.greenModeEnabled and true or false) end
    cb = getglobal("blueModeButtons");    if cb then cb:SetChecked(XyTrackerOptions.blueModeEnabled and true or false) end
    cb = getglobal("purpleModeButtons");  if cb then cb:SetChecked(XyTrackerOptions.purpleModeEnabled and true or false) end
    cb = getglobal("hideLeftButtons");    if cb then cb:SetChecked(XyTrackerOptions.HideLeftMembers ~= false) end
    XyTracker_UpdateList()
    SendAddonMessage("XY_SYNC_NEW", "", "RAID")

   
    
    -- 添加加减分数子菜单定义
    if not UnitPopupMenus["ADD_DKP"] then
        UnitPopupMenus["ADD_DKP"] = {
            "ADD_DKP_1",
            "ADD_DKP_2", 
            "ADD_DKP_3",
            "ADD_DKP_4"
        };
    end
    
    if not UnitPopupMenus["Minus_DKP"] then
        UnitPopupMenus["Minus_DKP"] = {
            "MINUS_DKP_1",
            "MINUS_DKP_2",
            "MINUS_DKP_3", 
            "MINUS_DKP_4"
        };
    end

	
	--增强CML拾取大师
	-- CML_Vars 的正式默认值在 VARIABLES_LOADED 才补齐（等 SavedVariables 恢复）；
	-- OnLoad 阶段它仍是 nil，这里先兜底建表并给菜单用到的键默认值，
	-- 避免其他插件（如 DPSMateX 包装的 UIDropDownMenu_Initialize）提前触发菜单初始化时索引 nil 报错
	if not CML_Vars then CML_Vars = {} end
	if not CML_Vars.Quickloot then CML_Vars.Quickloot = "" end
	-- 直接初始化自定义下拉菜单，不使用原始的GroupLootDropDown_Initialize函数
	UIDropDownMenu_Initialize(GroupLootDropDown, XYT_InitDropDown, "MENU");
	
end

-- 定义CML相关的本地化字符串
CML_Classes = {
    Druid = "德鲁伊",
    Hunter = "猎人",
    Mage = "法师",
    Paladin = "圣骑士",
    Priest = "牧师",
    Rogue = "盗贼",
    Shaman = "萨满祭司",
    Warlock = "术士",
    Warrior = "战士",
    Unknown = "未知",
    Random = "随机成员",
    Self = "自我拾取",
}

CML_ROLL_DROPDOWNMENU = "最佳(%d)个Roll点";
CML_RANDOMLOOT = "Roll点 %d -> 胜利者是 %s";
CML_ROLL_ANOUNCE_MESSAGE = "%s Roll点奖励开始,请大家输入 /random %d-%d ,或者/roll 进行roll点";
CML_ROLL_TABLE_HEADER = "最佳Roll点(点数 - 名字)";
CML_BIDBOT_DROPDOWNMENU = "BidBot 竞拍";
CML_ROLL_SEARCHPATTERN = "(.+)掷出(%d+)（(%d+)-(%d+)）";


-- 帮助函数：根据名字获取玩家ID（支持团队、队伍和自己）
function XYT_GetIDbyName(name)
    -- 首先在团队中查找
    for i = 1, GetNumRaidMembers() do
        if (UnitName("raid" .. i) == name) then
            return "raid" .. i;
        end
    end
    
    -- 如果团队中没找到，在队伍中查找
    for i = 1, GetNumPartyMembers() do
        if (UnitName("party" .. i) == name) then
            return "party" .. i;
        end
    end
    
    -- 检查是否是自己
    if (UnitName("player") == name) then
        return "player";
    end
    
    -- 如果都没找到，返回nil
    return nil;
end

-- 重置小地图图标位置的函数
function XyTracker_ResetMinimapButtonPosition()
    -- 获取小地图图标按钮
    local button = getglobal("XyTrackerMinimapButton")
    if button then
        -- 清除当前位置设置
        button:ClearAllPoints()
        
        -- 设置默认位置（小地图右侧）
        button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
        
        -- 重置为默认尺寸
        button:SetWidth(32)
        button:SetHeight(32)
        local normalTex = button.icon
        if normalTex then
            normalTex:SetWidth(20)
            normalTex:SetHeight(20)
        end
        -- 边框圆环恢复 32 档尺寸
        if button.border then
            button.border:SetWidth(53)
            button.border:SetHeight(53)
        end
        local highlightTex = button:GetHighlightTexture()
        if highlightTex then
            highlightTex:SetWidth(32)
            highlightTex:SetHeight(32)
        end
        
        -- 更新数据库中的位置信息
        if XyTrackerOptions then
            XyTrackerOptions.minimapPos = {x = -5, y = -5}
            XyTrackerOptions.minimapIsFree = false  -- 重置为围绕小地图模式
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 小地图图标已重置到默认位置")
    else
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 小地图图标未找到，可能尚未创建")
    end
end

-- 原 SLASH_XY1("/xy") 与 SLASH_XYTRACKER3 冲突，其 rl 子命令已并入 XyTracker_OnSlashCommand

-- 帮助函数：获取队伍类型
function XYT_GetGroupType()
    if (GetNumRaidMembers() > 0) then
        return "RAID";
    else
        return "PARTY";
    end
end


-- 分配物品给指定玩家
function XYT_GiveItTo(self, sourceMenu)
    local value = self and self.value or 0;
    value = tonumber(value) or 0;  -- 确保value是数字类型
    local playerName;
    
    -- 分配物品并获取玩家名称
    if value > 0 then
        playerName = GetMasterLootCandidate(value);
        local showDialog = false;
        
        if (CML_Vars.Ask) then
            showDialog = true;
        else
            if (LootFrame.selectedQuality) then
                if (LootFrame.selectedQuality >= 4) then -- 4表示紫色(史诗)品质
                    showDialog = true;
                end
            end
        end
        
        -- 分配物品
        if (showDialog) then
            local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION",
            (LootFrame.selectedQuality and ITEM_QUALITY_COLORS[LootFrame.selectedQuality].hex or "") .. (LootFrame.selectedItemName or "") .. FONT_COLOR_CODE_CLOSE,
            playerName);
            if (dialog) then
                dialog.data = value;
            end
        else
            GiveMasterLoot(LootFrame.selectedSlot, value);
        end

        -- 立即刷新拾取列表界面（仅在实际分配后）
        XyTracker_UpdateLootList();
    end

    -- 许愿完成由拾取消息（CHAT_MSG_LOOT）统一标记，此处不再提前标记（避免取消确认框时误标）
end

-- 分配物品给自己
function XYT_GiveToSelf()
    local myplayerid = 0;
    local selfName = UnitName("player");
    for i = 1, 40 do
        if (GetMasterLootCandidate(i) == selfName) then
            myplayerid = i;
            break;
        end
    end
    if (myplayerid > 0) then
        local showDialog = false;

        if (CML_Vars.Ask) then
            showDialog = true;
        else
            if (LootFrame.selectedQuality) then
                if (LootFrame.selectedQuality >= 4) then
                    showDialog = true;
                end
            end
        end

        if (showDialog) then
            LootFrame.value = myplayerid;
            LootFrame.text = GetMasterLootCandidate(myplayerid);

            local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION",
            (LootFrame.selectedQuality and ITEM_QUALITY_COLORS[LootFrame.selectedQuality].hex or "") .. (LootFrame.selectedItemName or "") .. FONT_COLOR_CODE_CLOSE,
            LootFrame.text);
            if (dialog) then
                dialog.data = LootFrame.value;
            end
        else
            GiveMasterLoot(LootFrame.selectedSlot, myplayerid);
        end

        -- 许愿完成由拾取消息（CHAT_MSG_LOOT）统一标记，此处不再提前标记（避免取消确认框时误标）
    end
end

-- 随机分配物品
function XYT_GiveToRandomTarget()
    if (GetNumRaidMembers() <= 0) then return; end
    
    local list_players = {};
    local winner = 0;
    local raidmembers = GetNumRaidMembers();
    local donotloopuntilworldexplode = time();

    -- 先建一次 候选人名字→lootid 映射，避免 40×40 双重循环
    local candidateIndex = {};
    for x = 1, 40 do
        local candidate = GetMasterLootCandidate(x);
        if (candidate) then
            candidateIndex[candidate] = x;
        end
    end

    for i = 1, raidmembers do
        list_players[i] = {};
        list_players[i]["rid"] = "raid" .. i;
        list_players[i]["name"] = UnitName(list_players[i]["rid"]);
        list_players[i]["lootid"] = 0;

        if (string.len(list_players[i]["name"] or "") > 0) then
            list_players[i]["lootid"] = candidateIndex[list_players[i]["name"]] or 0;
        end
    end

    winner = math.random(1, raidmembers);

    while (list_players[winner]["lootid"] == 0) do
        winner = math.random(1, raidmembers);
        if (donotloopuntilworldexplode < (time() - 2)) then
            return false;
        end
    end

    if (CML_Vars.PostRandom == true) then
        SendChatMessage(string.format(CML_RANDOMLOOT, winner, GetMasterLootCandidate(list_players[winner]["lootid"])), "SAY");
    end

    if (CML_Vars.Ask or (LootFrame.selectedQuality and LootFrame.selectedQuality >= 4)) then
        LootFrame.value = list_players[winner]["lootid"];
        LootFrame.text = GetMasterLootCandidate(list_players[winner]["lootid"]);

        local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION",
        (LootFrame.selectedQuality and ITEM_QUALITY_COLORS[LootFrame.selectedQuality].hex or "") .. (LootFrame.selectedItemName or "") .. FONT_COLOR_CODE_CLOSE,
        LootFrame.text);
        if (dialog) then
            dialog.data = LootFrame.value;
        end
    else
        GiveMasterLoot(LootFrame.selectedSlot, list_players[winner]["lootid"]);
    end
end





-- 主下拉菜单初始化函数
function XYT_InitDropDown()
	-- 不调用原始下拉菜单函数，避免与GroupRoster表交互导致的nil值错误
	-- 按照用户要求实现动态显示和鼠标滑过功能
	local menuValueDisplay = "nil";
	if UIDROPDOWNMENU_MENU_VALUE then
		if type(UIDROPDOWNMENU_MENU_VALUE) == "table" then
			menuValueDisplay = "[table]";
		else
			menuValueDisplay = tostring(UIDROPDOWNMENU_MENU_VALUE);
		end
	end
	-- 菜单初始化调试（需要时取消注释）
	-- ChatFrame1:AddMessage("[菜单] 层级: " .. UIDROPDOWNMENU_MENU_LEVEL .. ", 值: " .. menuValueDisplay);
	
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		-- 1. 增强拾取菜单（标题）
		UIDropDownMenu_AddButton {
			text = "增强拾取菜单",
			notCheckable = 1,
			isTitle = 1,
		}
		
		-- 自我拾取
		UIDropDownMenu_AddButton {
			text = "自我拾取",
			func = XYT_GiveToSelf,
		}
		
		-- 指定拾取：动态显示（设置了显示名字，没设置显示未设置）
		local quickLootText = "指定拾取：未设置";
		local quickLootHasArrow = true;
		
		-- 动态计算指定拾取文本（每次菜单初始化时重新计算）
		if (CML_Vars.Quickloot ~= "") then
			local id = XYT_GetIDbyName(CML_Vars.Quickloot);
			local class = "未知";
			if id then
				class = UnitClass(id) or "未知";
			end
			local classColor = XYT_GetClassColor(class);
			if classColor then
				quickLootText = "指定拾取：" .. classColor .. CML_Vars.Quickloot .. "\124r";
			else
				quickLootText = "指定拾取：" .. CML_Vars.Quickloot;
			end
		end
		
		-- 指定拾取
		UIDropDownMenu_AddButton({
			text = quickLootText,
			value = "QUICKLOOT",
			hasArrow = true,
			func = function()
					-- 先关闭之前的子菜单
					CloseDropDownMenus(2);
					-- 然后执行原有的快速拾取逻辑
					if (CML_Vars.Quickloot ~= "") then
						for i = 1, 40 do
							if (GetMasterLootCandidate(i) == CML_Vars.Quickloot) then
								XYT_GiveItTo({value = i});
								break;
							end
						end
					end
			end,
			onLeave = function()
				GameTooltip:Hide();
			end
		}, UIDROPDOWNMENU_MENU_LEVEL);

		-- 随机分配
		UIDropDownMenu_AddButton {
			text = "随机分配",
			func = XYT_GiveToRandomTarget,
		}
			
		-- 职业分配（支持团队和小队）
		if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
			UIDropDownMenu_AddButton {
				text = "职业分配",
				value = "CLASSLIST",
				hasArrow = 1,
				notCheckable = 1,
				-- 点击func已删除：悬停即展开子菜单（原func传入不存在的XYT_DropDownMenu且层级参数错误）
				onLeave = function()
					GameTooltip:Hide();
				end
			}
		end
			if IsLeader then
		-- 分隔空行已移除（用户反馈职业分配与许愿团菜单之间多余空行）
		
		-- 2. 许愿团菜单（标题）- 仅在团队领袖时显示
	
			UIDropDownMenu_AddButton {
				text = "许愿团菜单",
				notCheckable = 1,
				isTitle = 1,
			}
		
	
		end
		-- 显示许愿人数和玩家剩余分数
		local wishPlayers = XYT_GetWishPlayers();
		if table.getn(wishPlayers) > 0 then
			-- 分隔空行已移除（与许愿团菜单标题之间多余空行）
			
			-- 显示许愿人数
			UIDropDownMenu_AddButton {
				text = "【" .. table.getn(wishPlayers) .. "人许愿】",
				notCheckable = 1,
				isTitle = 1,
			}
			
			-- 显示所有许愿玩家（带职业染色）
			for i = 1, table.getn(wishPlayers) do
				local player = wishPlayers[i];
				local classColor = XYT_GetClassColor(player.class);
				local coloredName = player.name;
				if classColor then
					coloredName = classColor .. player.name .. "\124r";
				end
				
				-- 尝试找到玩家的索引（如果在团队中）
				local playerIndex = nil;
				for j = 1, 40 do
					if (GetMasterLootCandidate(j) == player.name) then
						playerIndex = j;
						break;
					end
				end
				
				-- 添加许愿玩家按钮，带鼠标悬停提示
				UIDropDownMenu_AddButton {
					text = "【" .. player.score .. "分】" .. coloredName,
					value = playerIndex,
					notCheckable = 0,
					func = function()
							if this.value and tonumber(this.value) and tonumber(this.value) > 0 then
								-- 直接分配物品给该玩家
								XYT_GiveItTo({value = this.value});
							else
								DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 无法分配物品：玩家" .. player.name .. "不在拾取候选人列表中");
							end
						end,
	
					onLeave = function()
						GameTooltip:Hide();
					end
				}
			end
		end
		
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		-- 第二层菜单处理
		

		
		-- 指定拾取菜单：显示许愿地板玩家 + 9职业分类
		if (UIDROPDOWNMENU_MENU_VALUE == "QUICKLOOT") then
			-- 首先显示许愿地板玩家（如果有）
				local wishPlayers = XYT_GetWishPlayers(true); -- 只获取许愿"地板"的玩家
			local hasWishPlayers = false;
			
			for i = 1, table.getn(wishPlayers) do
					local player = wishPlayers[i];
					-- 显示符合当前模式匹配的许愿玩家
					hasWishPlayers = true;
					local classColor = XYT_GetClassColor(player.class);
				local coloredName = player.name;
				if classColor then
					coloredName = classColor .. player.name .. "\124r";
				end
				
				-- 尝试找到玩家的索引（如果在团队中）
				local playerIndex = nil;
				for j = 1, 40 do
					if (GetMasterLootCandidate(j) == player.name) then
						playerIndex = j;
						break;
					end
				end
				
				-- 准备显示文本：显示玩家的实际许愿内容
						local displayText = coloredName;
						-- 如果有许愿内容，并且不是空的，添加到显示文本中
						if player.wishContent and player.wishContent ~= "" then
							-- 清理许愿内容，移除多余空格
							local cleanWishContent = string.gsub(string.gsub(player.wishContent, "^%s+", ""), "%s+$", "");
							-- 如果许愿内容不是数字（避免显示分数），则添加到显示文本
							if cleanWishContent ~= tostring(player.score) then
								displayText = displayText .. " ：" .. cleanWishContent;
							end
						end
						
						-- 如果找到索引，正常分配；否则设置为0作为特殊标记
						UIDropDownMenu_AddButton({
							text = displayText,
							value = playerIndex or 0,
							notCheckable = 1,
							func = function()
								if this.value and tonumber(this.value) and tonumber(this.value) > 0 then
									-- 找到索引的情况
									CML_Vars.Quickloot = player.name;
									XYT_GiveItTo(this);
								else
									-- 没找到索引的情况，至少可以设置为快速拾取人
									CML_Vars.Quickloot = player.name;
									DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. player.name .. " 已设置为快速拾取人，但当前不在拾取候选人列表中");
								end
								-- 立即刷新拾取菜单，显示当前选定的玩家
								CloseDropDownMenus();
								-- 强制重新初始化菜单
								UIDropDownMenu_Initialize(GroupLootDropDown, XYT_InitDropDown, "MENU");
								ToggleDropDownMenu(1, nil, GroupLootDropDown, "cursor", 0, 0, nil, nil, 1);
							end,
			
		
							onLeave = function()
								GameTooltip:Hide();
							end
						}, UIDROPDOWNMENU_MENU_LEVEL);
			end
			
			
			-- 如果没有许愿地板玩家，添加一个提示
			if not hasWishPlayers then
				UIDropDownMenu_AddButton({
					text = "暂无许愿地板玩家",
					notCheckable = 1,
					isTitle = 1,
				}, UIDROPDOWNMENU_MENU_LEVEL);
			else
				-- 添加分隔线
				UIDropDownMenu_AddButton({}, UIDROPDOWNMENU_MENU_LEVEL);
			end
			
			-- 然后显示9职业带染色
			local allClasses = {"战士", "圣骑士", "猎人", "盗贼", "牧师", "萨满祭司", "法师", "术士", "德鲁伊"};
			for _, class in ipairs(allClasses) do
				local classColor = XYT_GetClassColor(class);
				local coloredClass = class;
				if classColor then
					coloredClass = classColor .. class .. "\124r";
				end
				
				-- 为指定拾取下的职业添加鼠标悬停提示，显示该职业的所有角色名
				local menuLevel = UIDROPDOWNMENU_MENU_LEVEL;
				
				-- 先创建按钮
										UIDropDownMenu_AddButton({
						text = coloredClass,
						value = class,
						hasArrow = 1,
						notCheckable = 1,
						-- 点击func已删除（含调试打印和错误层级的ToggleDropDownMenu调用）：悬停即展开子菜单
					-- 移除自动悬停触发子菜单，避免菜单堆叠时的冲突
					OnEnter = function()
						-- 只显示工具提示，不自动打开子菜单
						local roleNames = "";
						local memberCount = GetNumRaidMembers();
						if memberCount > 0 then
							-- 团队状态
							for i = 1, memberCount do
								local name, _, _, _, unitClass = GetRaidRosterInfo(i);
								if name and unitClass == class then
									if roleNames ~= "" then
										roleNames = roleNames .. ", ";
									end
									roleNames = roleNames .. name;
								end
							end
						else
							-- 小队状态
							local partyCount = GetNumPartyMembers();
							for i = 1, partyCount do
								local name = UnitName("party" .. i);
								local unitClass = UnitClass("party" .. i);
								if name and unitClass == class then
									if roleNames ~= "" then
										roleNames = roleNames .. ", ";
									end
									roleNames = roleNames .. name;
								end
							end
							-- 检查玩家自己
							local playerName = UnitName("player");
							local playerClass = UnitClass("player");
							if playerClass == class then
								if roleNames ~= "" then
									roleNames = roleNames .. ", ";
								end
								roleNames = roleNames .. playerName;
							end
						end
						if roleNames ~= "" then
							GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
							GameTooltip:SetText(class .. "角色：" .. roleNames);
							GameTooltip:Show();
						end
					end
					}, menuLevel);
				
			end
			-- 获取正确的菜单值
			local menuValue = UIDROPDOWNMENU_MENU_VALUE;
			-- 在魔兽世界1.12中，值可能通过this参数传递
			if not menuValue and this and this.value then
				menuValue = this.value;
				
            end
	-- 职业分配子菜单
	elseif (UIDROPDOWNMENU_MENU_VALUE == "CLASSLIST") then
		-- 显示所有有拾取权限的职业（带染色）
		local raidmembers = {};

		-- 收集所有职业信息（支持团队和小队）
		local memberCount = GetNumRaidMembers();
		if memberCount > 0 then
			-- 团队状态
			for i = 1, 40 do
				local candidate = GetMasterLootCandidate(i);
				if (candidate) then
					local id = XYT_GetIDbyName(candidate);
					if (id) then
						local classx = UnitClass(id);
						if (classx) then
							local normalizedClass = XyTracker_GetNormalizedClassName(classx);
							if normalizedClass then
								raidmembers[normalizedClass] = true;
							end
						end
					end
				end
			end
		else
			-- 小队状态
			local partyCount = GetNumPartyMembers();
			for i = 1, partyCount do
				local name = UnitName("party" .. i);
				local unitClass = UnitClass("party" .. i);
				if name and unitClass then
					local normalizedClass = XyTracker_GetNormalizedClassName(unitClass);
					if normalizedClass then
						raidmembers[normalizedClass] = true;
					end
				end
			end
			-- 检查玩家自己
			local playerName = UnitName("player");
			local playerClass = UnitClass("player");
			if playerName and playerClass then
				local normalizedPlayerClass = XyTracker_GetNormalizedClassName(playerClass);
				if normalizedPlayerClass then
					raidmembers[normalizedPlayerClass] = true;
				end
			end
		end

		-- 按职业排序并添加到菜单
		local classes = {}
		for class in pairs(raidmembers) do
			table.insert(classes, class);
		end
		table.sort(classes)

		for i = 1, table.getn(classes) do
				local class = classes[i];
				local classColor = XYT_GetClassColor(class);
				local coloredClass = class;
				if classColor then
					coloredClass = classColor .. class .. "\124r";
				end

				-- 完全照搬ClassMasterLoot的实现方式
				UIDropDownMenu_AddButton({
						text = coloredClass,
						value = "CLASS_" .. class, -- 使用固定格式的value
						hasArrow = 1,
						notCheckable = 1,

						onLeave = function()
							GameTooltip:Hide();
						end
					}, UIDROPDOWNMENU_MENU_LEVEL);


		end
	end

	elseif UIDROPDOWNMENU_MENU_LEVEL == 3 then
		-- 第三层菜单处理
		
		
		-- 处理指定拾取下的职业子菜单 - 显示该职业的所有角色
		if UIDROPDOWNMENU_MENU_VALUE and type(UIDROPDOWNMENU_MENU_VALUE) == "string" then
			local targetClass = UIDROPDOWNMENU_MENU_VALUE;
			local hasPlayers = false;
			
			-- 检查是否是职业分配下的CLASS_前缀
			local isClassLooters = false;
			if (strfind(targetClass, "CLASS_") == 1) then
				targetClass = strsub(targetClass, 7); -- 移除CLASS_前缀
				isClassLooters = true; -- 标记这是职业分配菜单
			end
			

			
			if isClassLooters then
				-- 职业分配菜单：只显示有拾取权限的玩家
				for i = 1, 40 do
					local candidate = GetMasterLootCandidate(i);
					if (candidate) then
						local playerClass = nil;
						local id = XYT_GetIDbyName(candidate);
						
						-- 尝试通过UnitClass获取职业
						if (id) then
							playerClass = UnitClass(id);
						end
						
						-- 如果UnitClass失败，从XyArray中查找
						if not playerClass and XyArray and type(XyArray) == "table" then
							for _, info in ipairs(XyArray) do
								if info and info["name"] == candidate and info["class"] then
									playerClass = info["class"];
									break;
								end
							end
						end
						
						-- 如果找到匹配的职业，添加到菜单
						if (playerClass == targetClass) then
							hasPlayers = true;
							local classColor = XYT_GetClassColor(targetClass);
							local coloredName = candidate;
							if classColor then
								coloredName = classColor .. candidate .. "\124r";
							end
							
							UIDropDownMenu_AddButton({
									text = coloredName,
									value = i,
									notCheckable = 1,
									func = function()
									-- 职业分配：直接分配物品，不设置快速拾取人
									XYT_GiveItTo(this);
									-- 记录分配成功的消息
									DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 物品已分配给 " .. candidate);
									-- 关闭菜单
									CloseDropDownMenus();
							end,
									onLeave = function()
										GameTooltip:Hide();
									end
							}, UIDROPDOWNMENU_MENU_LEVEL);
						end
					end
				end
			else
				-- 指定拾取菜单：根据团队/小队状态显示该职业的所有成员
				local memberCount = GetNumRaidMembers();
				if memberCount > 0 then
					-- 团队状态：使用GetRaidRosterInfo
					for i = 1, memberCount do
						local name, _, _, _, unitClass = GetRaidRosterInfo(i);
						
						-- 标准化职业名称
						local normalizedUnitClass = XyTracker_GetNormalizedClassName(unitClass);
						local normalizedTargetClass = XyTracker_GetNormalizedClassName(targetClass);
						
						if name and normalizedUnitClass and normalizedUnitClass == normalizedTargetClass then
							hasPlayers = true;
							local classColor = XYT_GetClassColor(normalizedUnitClass);
							local coloredName = name;
							if classColor then
								coloredName = classColor .. name .. "\124r";
							end
							
							UIDropDownMenu_AddButton({
								text = coloredName,
								value = name,
								notCheckable = 1,
								func = function()
											-- 设置为快速拾取人
											CML_Vars.Quickloot = name;
											-- 记录设置成功的消息
											DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. name .. " 已设置为快速拾取人");
											-- 关闭菜单
											CloseDropDownMenus();
											-- 立即刷新主菜单，显示当前选定的玩家
											if GroupLootDropDown and XYT_InitDropDown then
												UIDropDownMenu_Initialize(GroupLootDropDown, XYT_InitDropDown, "MENU");
											end
								end,

								onLeave = function()
									GameTooltip:Hide();
								end
							}, UIDROPDOWNMENU_MENU_LEVEL);
						end
					end
				else
					-- 小队状态：使用UnitName和UnitClass
					local partyCount = GetNumPartyMembers();
					for i = 1, partyCount do
						local name = UnitName("party" .. i);
						local unitClass = UnitClass("party" .. i);
						
						if name and unitClass then
							local normalizedUnitClass = XyTracker_GetNormalizedClassName(unitClass);
							local normalizedTargetClass = XyTracker_GetNormalizedClassName(targetClass);
							
							if normalizedUnitClass and normalizedUnitClass == normalizedTargetClass then
								hasPlayers = true;
								local classColor = XYT_GetClassColor(normalizedUnitClass);
								local coloredName = name;
								if classColor then
									coloredName = classColor .. name .. "\124r";
								end
								
								UIDropDownMenu_AddButton({
									text = coloredName,
									value = name,
									notCheckable = 1,
									func = function()
												-- 设置为快速拾取人
												CML_Vars.Quickloot = name;
												-- 记录设置成功的消息
												DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. name .. " 已设置为快速拾取人");
												-- 关闭菜单
												CloseDropDownMenus();
												-- 立即刷新主菜单，显示当前选定的玩家
												if GroupLootDropDown and XYT_InitDropDown then
													UIDropDownMenu_Initialize(GroupLootDropDown, XYT_InitDropDown, "MENU");
												end
									end,

									onLeave = function()
										GameTooltip:Hide();
									end
								}, UIDROPDOWNMENU_MENU_LEVEL);
							end
						end
					end
					
					-- 检查玩家自己
					local playerName = UnitName("player");
					local playerClass = UnitClass("player");
					if playerName and playerClass then
						local normalizedPlayerClass = XyTracker_GetNormalizedClassName(playerClass);
						local normalizedTargetClass = XyTracker_GetNormalizedClassName(targetClass);
						
						if normalizedPlayerClass and normalizedPlayerClass == normalizedTargetClass then
							hasPlayers = true;
							local classColor = XYT_GetClassColor(normalizedPlayerClass);
							local coloredName = playerName;
							if classColor then
								coloredName = classColor .. playerName .. "\124r";
							end
							
							UIDropDownMenu_AddButton({
								text = coloredName,
								value = playerName,
								notCheckable = 1,
								func = function()
											-- 设置为快速拾取人
											CML_Vars.Quickloot = playerName;
											-- 记录设置成功的消息
											DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. playerName .. " 已设置为快速拾取人");
											-- 关闭菜单
											CloseDropDownMenus();
											-- 立即刷新主菜单，显示当前选定的玩家
											if GroupLootDropDown and XYT_InitDropDown then
												UIDropDownMenu_Initialize(GroupLootDropDown, XYT_InitDropDown, "MENU");
											end
								end,

							onLeave = function()
									GameTooltip:Hide();
								end
							}, UIDROPDOWNMENU_MENU_LEVEL);
						end
					end
				end
			end
			
			-- 如果该职业没有玩家，添加提示
			if not hasPlayers then
				local tipText;
				if isClassLooters then
					tipText = "该职业暂无可拾取的玩家";
				else
					tipText = "该职业暂无团队成员";
				end
				
				UIDropDownMenu_AddButton({
					text = tipText,
					notCheckable = 1,
					disabled = 1,
				}, UIDROPDOWNMENU_MENU_LEVEL);
			end
		end
	end
end



-- 获取许愿玩家列表

-- 兼容Lua 5.0的unpack替代函数
function XYT_Unpack(tbl, startIdx, endIdx)
    startIdx = startIdx or 1;
    endIdx = endIdx or table.getn(tbl);
    
    if startIdx > endIdx then
        return;
    end
    
    return tbl[startIdx], XYT_Unpack(tbl, startIdx + 1, endIdx);
end

-- 判断许愿是否已"整体完成"（拾取菜单中不再显示该玩家）
-- 注意：多物品许愿部分完成时字符串形如 "|cFF00FFFF【已完成许愿】|r[物品B]"，仍算未完成
local function XyTracker_IsWishFullyCompleted(xy)
    if not xy or xy == "" then return false end
    if not string.find(xy, "已完成许愿") then return false end
    -- 去掉颜色代码和完成标记后还有内容 = 部分完成
    local rest = string.gsub(xy, "|c%x%x%x%x%x%x%x%x", "")
    rest = string.gsub(rest, "|r", "")
    rest = string.gsub(rest, "【已完成许愿】", "")
    rest = string.gsub(rest, "已完成许愿", "")
    rest = string.gsub(rest, "%s", "")
    return rest == ""
end

function XYT_GetWishPlayers(onlyFloorWish)
	local players = {};
	local checkedPlayers = {}; -- 用于去重
	local isQuickLootMode = (onlyFloorWish == true); -- 是否只匹配"地板"许愿的玩家，不匹配任何物品许愿
	
	-- 函数开始执行
	
	
	-- 快速拾取模式下不需要获取当前物品信息，只关注地板许愿
	local currentItem = nil;
	local currentItemName = nil;
	local cleanCurrentItemName = "";
	
	-- 非快速拾取模式下才获取当前物品信息
	if not isQuickLootMode then
		-- 优先获取当前选中的拾取槽物品（菜单是按选中槽打开的）
		if LootFrame.selectedSlot then
			currentItem = GetLootSlotLink(LootFrame.selectedSlot);
		end

		-- 选中槽取不到时回退原逻辑：获取第一个有效拾取槽物品
		if not currentItem then
			local numItems = GetNumLootItems();

			if numItems > 0 then
				-- 1.12 的 GetLootSlotInfo 只返回5个值，直接按链接是否有效判断
				for i = 1, numItems do
					currentItem = GetLootSlotLink(i);
					if currentItem then
						break;
					end
				end
			end
		end
		
		if currentItem then
			-- 从当前物品链接中提取物品名称
			currentItemName = currentItem and string.match(currentItem, "|h%[(.-)%]|h") or currentItem;
			cleanCurrentItemName = currentItemName and safeCleanString(currentItemName) or "";
		end
	end
	
	
	-- 方法2：尝试从XyArray获取地板许愿信息和物品许愿信息
	if XyArray and type(XyArray) == "table" then
		for _, playerData in ipairs(XyArray) do
			if playerData and playerData["name"] and not checkedPlayers[playerData["name"]] and playerData["xy"] and playerData["xy"] ~= "" and playerData["xy"] ~= "---未许愿---" and not XyTracker_IsWishFullyCompleted(playerData["xy"]) then
				-- 检查玩家的许愿内容是否与当前物品匹配，或者是否许愿了"地板"
						local isMatched = false;
						local wishContent = playerData["xy"];
						
						if wishContent then
							local cleanWishContent = safeCleanString(wishContent);
							
							if isQuickLootMode then
						-- 快速拾取模式：严格只匹配纯"地板"许愿的玩家，排除任何物品许愿
						isMatched = (cleanWishContent == "地板");
							elseif currentItem then
								-- 正常模式：匹配具体物品
								isMatched = (cleanWishContent == cleanCurrentItemName or 
								           string.find(cleanWishContent, cleanCurrentItemName, 1, true) or 
								           string.find(cleanCurrentItemName, cleanWishContent, 1, true));
							end
						
					-- 在快速拾取模式下，不进行任何额外的物品匹配尝试
					if not isMatched and not isQuickLootMode and currentItem then
						local success, primaryWishItem, allWishItems = pcall(ExtractItemName, wishContent);
						if success then
							-- 检查主物品名称
							if primaryWishItem then
								local cleanPrimaryWishItem = safeCleanString(primaryWishItem);
								isMatched = (cleanPrimaryWishItem == cleanCurrentItemName or 
								           string.find(cleanPrimaryWishItem, cleanCurrentItemName, 1, true) or 
								           string.find(cleanCurrentItemName, cleanPrimaryWishItem, 1, true));
							end
							
							-- 如果主物品不匹配，检查其他物品名称
							if not isMatched and type(allWishItems) == "table" then
								for _, wishItem in ipairs(allWishItems) do
									local cleanWishItem = safeCleanString(wishItem);
									if cleanWishItem == cleanCurrentItemName or 
									   string.find(cleanWishItem, cleanCurrentItemName, 1, true) or 
									   string.find(cleanCurrentItemName, cleanWishItem, 1, true) then
										isMatched = true;
										break;
									end
								end
							end
						end
					end
				end
						if isMatched then
						local name = playerData["name"];
						local class = playerData["class"] or "未知";
						local score = tonumber(playerData["score"]) or tonumber(playerData["dkp"]) or 0;
						local wishContent = playerData["xy"] or "";
						table.insert(players, {name = name, score = score, class = class, wishContent = wishContent});
						checkedPlayers[name] = true;
					end
					end
				end
	end
	
	-- 方法3：检查当前物品是否有特定的许愿记录（只在有currentItem且非快速拾取模式时执行）
	-- 快速拾取模式下完全跳过LootList处理，因为它只包含物品许愿
	if not isQuickLootMode and currentItem and LootList and type(LootList) == "table" then
		for _, lootData in ipairs(LootList) do
			if lootData and lootData["isWish"] and lootData["playerName"] and not checkedPlayers[lootData["playerName"]] then
				-- 检查该记录是否与当前物品相关
						local isMatched = false; -- 默认不匹配
						
						if lootData["itemName"] and currentItem then
							local lootItemName = lootData["itemName"];
							local cleanLootItemName = safeCleanString(lootItemName);
							isMatched = (cleanLootItemName == cleanCurrentItemName or 
							           string.find(cleanLootItemName, cleanCurrentItemName, 1, true) or 
							           string.find(cleanCurrentItemName, cleanLootItemName, 1, true));
						end
				
				if isMatched then
				local name = lootData["playerName"];
				local id = XYT_GetIDbyName(name);
				local class = "未知";
				if id then
					class = UnitClass(id) or "未知";
				end
				-- 显示玩家当前剩余分数：拾取记录里没有 score 字段（只有 points），需从 XyArray 查
				-- 顺带判断：当前许愿已整体完成的玩家不再显示
				local score = 0;
				local fullyCompleted = false;
				if XyArray then
					for _, xyData in ipairs(XyArray) do
						if xyData and xyData["name"] == name then
							score = tonumber(xyData["dkp"]) or 0;
							fullyCompleted = XyTracker_IsWishFullyCompleted(xyData["xy"]);
							break;
						end
					end
				end
				if not fullyCompleted then
					local wishContent = lootData["itemName"] or "";
					table.insert(players, {name = name, score = score, class = class, wishContent = wishContent});
					checkedPlayers[name] = true;
				end
			end
			end
		end
	end
	
	-- 按分数降序排序
	table.sort(players, function(a, b) return a.score > b.score; end);
	
	return players;
end

-- 职业名称标准化函数
function XyTracker_GetNormalizedClassName(className)
    -- 职业名称映射表 - 支持中英文
    local classNames = {
        -- 中文职业名称
        ["战士"] = "战士",
        ["圣骑士"] = "圣骑士",
        ["猎人"] = "猎人",
        ["盗贼"] = "盗贼",
        ["牧师"] = "牧师",
        ["萨满祭司"] = "萨满祭司", 
        ["法师"] = "法师",
        ["术士"] = "术士",
        ["德鲁伊"] = "德鲁伊",

        ["Warrior"] = "战士",
        ["Paladin"] = "圣骑士",
        ["Hunter"] = "猎人",
        ["Rogue"] = "盗贼",
        ["Priest"] = "牧师",
        ["Shaman"] = "萨满祭司",
        ["Mage"] = "法师",
        ["Warlock"] = "术士",
        ["Druid"] = "德鲁伊",
        ["未知"] = "未知",
        ["Unknown"] = "未知",
    };
    
    -- 安全检查className是否为字符串
    if type(className) == "string" then
        return classNames[className] or "未知";
    end
    return "未知";
end










-- 替换后的单位弹出窗口点击处理函数
function ple_unitpopup1()
    local dropdownFrame = getglobal(UIDROPDOWNMENU_INIT_MENU);
    local button = this.value;
    local unit = dropdownFrame.unit;
    local name = dropdownFrame.name;
    local server = dropdownFrame.server;

    if (button == "GET_XY") then
        XyQuery(name);
    -- 处理增加分数的子菜单
    elseif button == "ADD_DKP_1" then
        XyAddDkp(name, 1);
    elseif button == "ADD_DKP_2" then
        XyAddDkp(name, 2);
    elseif button == "ADD_DKP_3" then
        XyAddDkp(name, 3);
    elseif button == "ADD_DKP_4" then
        XyAddDkp(name, 4);
    -- 处理扣除分数的子菜单
    elseif button == "MINUS_DKP_1" then
        XyMinusDkp(name, 1);
    elseif button == "MINUS_DKP_2" then
        XyMinusDkp(name, 2);
    elseif button == "MINUS_DKP_3" then
        XyMinusDkp(name, 3);
    elseif button == "MINUS_DKP_4" then
        XyMinusDkp(name, 4);

    else
        return ori_unitpopup1();
    end
    
    PlaySound("UChatScrollButton");
end

-- 获取指定名字的许愿信息
-- 性能：getXyInfo 名字→索引缓存。XyArray 引用或长度变化时自动重建（条目内容原地修改不影响映射）
local XyInfoIndexCache = nil
local XyInfoCacheArrayRef = nil
local XyInfoCacheArrayLen = -1

local function XyInfo_RebuildCache()
    XyInfoIndexCache = {}
    for i = 1, table.getn(XyArray) do
        local nm = XyArray[i] and XyArray[i]["name"]
        if nm and not XyInfoIndexCache[nm] then
            XyInfoIndexCache[nm] = i
        end
    end
    XyInfoCacheArrayRef = XyArray
    XyInfoCacheArrayLen = table.getn(XyArray)
end

function getXyInfo(name)
    -- 缓存有效性检查：XyArray 被整体重新赋值或长度变化时重建
    if XyInfoCacheArrayRef ~= XyArray or XyInfoCacheArrayLen ~= table.getn(XyArray) then
        XyInfo_RebuildCache()
    end
    local idx = XyInfoIndexCache[name]
    if idx then
        local info = XyArray[idx]
        if info and info["name"] == name then
            -- 修复：确保dkp值转换为数字并处理nil情况
            info["dkp"] = tonumber(info["dkp"]) or tonumber(DefaultDKP) or 0
            return info
        end
    end
    -- 缓存可能因原地排序等原因过期：先做一次线性查找兜底，避免重复插入同名行
    for i = 1, table.getn(XyArray) do
        local info = XyArray[i]
        if info and info["name"] == name then
            XyInfoIndexCache[name] = i  -- 顺带修正缓存
            info["dkp"] = tonumber(info["dkp"]) or tonumber(DefaultDKP) or 0
            return info
        end
    end
    --如果是新加入的成员。初始化该成员信息并返回 by 无道暴君20250217
    local totalMembers = GetNumRaidMembers()
    if totalMembers and totalMembers > 0 then
        for i = 1, totalMembers do
            local player, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i);
            if name==player then
                local info = {}
                info["name"] = name
                info["class"] = class
                info["xy"] = "---未许愿---"
                info["dkp"] = tonumber(DefaultDKP) or 0
                info["timestamp"] = time() -- 添加时间戳
                table.insert(XyArray, info)
                -- 同步更新缓存，避免立即重建
                XyInfoIndexCache[name] = table.getn(XyArray)
                XyInfoCacheArrayLen = table.getn(XyArray)
                NoXyList = NoXyList .. name .. " "
                return info;
            end
        end
    end
    return nil
end

-- Xy_CompareRolls函数已移至XYT_UpdateRollDisplay函数附近



-- 更新许愿者列表
function XyTracker_UpdateList()
    NoXyList = ""
    Xys = 0
    local totalMembers = GetNumRaidMembers()
    local currentRaidMembers = {}
    
    -- 获取当前团队成员列表
    if totalMembers and totalMembers > 0 then
        for i = 1, totalMembers do
            local name = GetRaidRosterInfo(i)
            if name then
                currentRaidMembers[name] = true
            end
        end
        
        -- 更新未许愿列表和许愿人数
        -- 先创建一个名字到索引的映射，用于快速查找
        local nameToIndex = {}
        local n = table.getn(XyArray)
        for i = 1, n do
            if XyArray[i] and XyArray[i]["name"] then
                nameToIndex[XyArray[i]["name"]] = i
            end
        end
        
        for i = 1, totalMembers do
            local name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(i);
            
            -- 使用映射表检查玩家是否存在
            local info = nil
            if name then
                if nameToIndex[name] then
                    info = XyArray[nameToIndex[name]]
                else
                    -- 玩家不存在，添加新记录
                    info = {}
                info["name"] = name
                info["class"] = class
                info["xy"] = "---未许愿---"
                info["dkp"] = tonumber(DefaultDKP) or 0
                info["timestamp"] = time() -- 添加时间戳
                table.insert(XyArray, info)
                nameToIndex[name] = table.getn(XyArray)
                end
                
                if info then
                    if IsLeader and NewDKP then 
                        info["dkp"] = tonumber(DefaultDKP) or 0
                    end
                    if info["xy"] and info["xy"] ~= "---未许愿---" and info["xy"] ~= "" then
                        Xys = Xys + 1
                    else
                        NoXyList = NoXyList .. name .. " "
                    end
                end
            end
        end
        
        -- 保留所有玩家记录，不在队伍中的玩家只是在UI中隐藏而不删除
        
        if IsLeader then
            NewDKP = false
        end
    end
    
    -- 确保总是显示未许愿人数，即使totalMembers为0
    if totalMembers and totalMembers > 0 then
        XyTrackerFrameStatusText:SetText(XyTracker_If(Xys == totalMembers, "当前全部许愿", string.format("%d未许愿人数", totalMembers - Xys)))
    else
        XyTrackerFrameStatusText:SetText("当前不在团队中")
    end
    
    -- 确保文本框总是可见
    if XyTrackerFrameStatusText:IsVisible() == false then
        XyTrackerFrameStatusText:Show()
    end
    
    -- 勾选"隐藏离队人员"且在团队中时，列表只保留当前在团成员；
    -- 不勾选（或不在团队中）则显示全部记录，离队人员灰色显示
    local displayList = XyArray
    if XyTrackerOptions.HideLeftMembers ~= false and totalMembers and totalMembers > 0 then
        displayList = {}
        for i = 1, table.getn(XyArray) do
            local info = XyArray[i]
            if info and info["name"] and currentRaidMembers[info["name"]] then
                table.insert(displayList, info)
            end
        end
    end
    local displayCount = table.getn(displayList)

    -- 更新滚动框
    FauxScrollFrame_Update(XyListScrollFrame, displayCount, 18, 25);

    if displayCount > 0 then
        local offset = FauxScrollFrame_GetOffset(XyListScrollFrame);
        for i = 1, 18 do
            local k = offset + i;
            if k > displayCount then
                getglobal("XyFrameListButton" .. i):Hide();
            else
                local v = displayList[k]
                
                -- 检查玩家是否在当前团队中
                local isInCurrentRaid = currentRaidMembers[v["name"]]
                
                -- 获取职业颜色并给名字染色，不在团队的玩家用灰色显示
                local classColor
                if isInCurrentRaid then
                    classColor = XYT_GetClassColor(v["class"]) or "|cffffffff"
                else
                    classColor = "|cff888888"  -- 灰色表示不在当前团队
                end
                
                local coloredName = classColor .. v["name"] .. "|r"
                getglobal("XyFrameListButton" .. i .. "Name"):SetText(coloredName);
                
                -- 显示完整职业名称，不在团队的用灰色
                if isInCurrentRaid then
                    getglobal("XyFrameListButton" .. i .. "Class"):SetText(v["class"]);
                    getglobal("XyFrameListButton" .. i .. "Xy"):SetText(v["xy"]);
                    getglobal("XyFrameListButton" .. i .. "DKP"):SetText(v["dkp"]);
                else
                    getglobal("XyFrameListButton" .. i .. "Class"):SetText("|cff888888" .. v["class"] .. "|r");
                    getglobal("XyFrameListButton" .. i .. "Xy"):SetText("|cff888888" .. v["xy"] .. "|r");
                    getglobal("XyFrameListButton" .. i .. "DKP"):SetText("|cff888888" .. v["dkp"] .. "|r");
                end
                
                getglobal("XyFrameListButton" .. i):Show();
                
                -- 显式显示加减按钮，仅在获得IsLeader权限时显示
                local addButton = getglobal("XyFrameListButton" .. i .. "AddDkp")
                local minusButton = getglobal("XyFrameListButton" .. i .. "MinusDkp")
                local completeButton = getglobal("XyFrameListButton" .. i .. "CompleteWish")
                if IsLeader then
                    if addButton then
                        addButton:Show()
                    end
                    if minusButton then
                        minusButton:Show()
                    end
                    if completeButton then
                        completeButton:Show()
                    end
                else
                    if addButton then
                        addButton:Hide()
                    end
                    if minusButton then
                        minusButton:Hide()
                    end
                    if completeButton then
                        completeButton:Hide()
                    end
                end
            end
        end
    else
        for i = 1, 18 do
            getglobal("XyFrameListButton" .. i):Hide();
        end
    end
end

-- 调试级别定义
XyTracker_DebugLevel = {
    ERROR = 1,    -- 仅错误信息
    WARN = 2,     -- 警告和错误
    INFO = 3,     -- 一般信息
    DEBUG = 4     -- 详细调试信息
}

-- 当前调试级别（默认仅显示错误）
XyTracker_CurrentDebugLevel = XyTracker_DebugLevel.ERROR

-- 新的调试输出函数
function XyTracker_Print(msg, level)
    level = level or XyTracker_DebugLevel.INFO
    if level <= XyTracker_CurrentDebugLevel then
        if DEFAULT_CHAT_FRAME then
            local levelText = ""
            if level == XyTracker_DebugLevel.ERROR then
                levelText = "|cffff0000[错误]|r"
            elseif level == XyTracker_DebugLevel.WARN then
                levelText = "|cffffff00[警告]|r"
            elseif level == XyTracker_DebugLevel.INFO then
                levelText = "|cff00ff00[信息]|r"
            elseif level == XyTracker_DebugLevel.DEBUG then
                levelText = "|cff808080[调试]|r"
            end
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] "..levelText.." "..msg)
        end
    end
end

function XyTracker_If(expr, a, b)
    if expr then
        return a
    else
        return b
    end
end
function XyTracker_OnSlashCommand(msg)
    XyTracker_Print("收到斜杠命令: " .. (msg or "空"), XyTracker_DebugLevel.DEBUG)
    
    -- 调试级别控制
    if msg == "debug0" then
        XyTracker_CurrentDebugLevel = XyTracker_DebugLevel.ERROR
        XyTracker_Print("调试级别切换为: ERROR (0)", XyTracker_DebugLevel.INFO)
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 调试级别设置为：仅错误")
    elseif msg == "debug1" then
        XyTracker_CurrentDebugLevel = XyTracker_DebugLevel.WARN
        XyTracker_Print("调试级别切换为: WARN (1)", XyTracker_DebugLevel.INFO)
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 调试级别设置为：警告和错误")
    elseif msg == "debug2" then
        XyTracker_CurrentDebugLevel = XyTracker_DebugLevel.INFO
        XyTracker_Print("调试级别切换为: INFO (2)", XyTracker_DebugLevel.INFO)
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 调试级别设置为：一般信息")
    elseif msg == "debug3" then
        XyTracker_CurrentDebugLevel = XyTracker_DebugLevel.DEBUG
        XyTracker_Print("调试级别切换为: DEBUG (3) - 详细调试模式已启用", XyTracker_DebugLevel.INFO)
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 调试级别设置为：详细调试")
    elseif msg == "export" then
        -- 导出功能已移除，打印提示避免落入默认显示/隐藏分支
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 导出功能已移除")
    elseif string.lower(msg or "") == "rl" then
        -- 重置小地图图标位置（原独立 /xy 命令的 rl 子命令并入）
        XyTracker_ResetMinimapButtonPosition()
    elseif msg == "backup" then
        -- 立即备份许愿数据到 Imports 目录（需 SuperWoW，见 XyTracker_Backup.lua）
        XyTracker_Backup_ForceSave()
    elseif msg == "restore" then
        -- 恢复许愿数据（优先 Imports 文件备份，回退 SavedVariables 快照）
        XyTracker_RestoreWishList()
        XyTracker_UpdateList()
    elseif string.find(msg, "^autobackup") then
        -- 开关自动备份：/xy autobackup on|off
        local _, _, newMode = string.find(msg, "^autobackup%s+(%S+)")
        if newMode == "on" or newMode == "off" then
            XyTrackerOptions.WishAutoBackupEnabled = (newMode == "on")
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 许愿数据自动备份: " .. newMode)
        else
            local curMode = "on"
            if XyTrackerOptions.WishAutoBackupEnabled == false then curMode = "off" end
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 用法: /xy autobackup on|off （当前: " .. curMode .. "）")
        end
    else
        -- 原有的显示/隐藏功能
          XyTracker_OnRefreshButtonClick()
        if XyTrackerFrame:IsVisible() then
            XyTracker_HideXyWindow()
          
        else
            XyTracker_ShowXyWindow()
        end
    end
end

function XyTracker_ShowXyWindow()
    if DefaultDKP == nil then
        DefaultDKP = 4
    end
    -- 恢复六个模式复选框的勾选状态（SavedVariables 此时已加载，开窗时同步显示）
    local cb
    cb = getglobal("autoModeButtons");    if cb then cb:SetChecked(XyTrackerOptions.XyOnlyMode == 1) end
    cb = getglobal("autoAnnounceButton"); if cb then cb:SetChecked(XyTrackerOptions.AutoAnnounce and true or false) end
    cb = getglobal("autoBackupButton");    if cb then cb:SetChecked(XyTrackerOptions.WishAutoBackupEnabled ~= false) end
    cb = getglobal("autoMinButtons");     if cb then cb:SetChecked(XyTrackerOptions.autoMinDkp and true or false) end
    cb = getglobal("greenModeButtons");   if cb then cb:SetChecked(XyTrackerOptions.greenModeEnabled and true or false) end
    cb = getglobal("blueModeButtons");    if cb then cb:SetChecked(XyTrackerOptions.blueModeEnabled and true or false) end
    cb = getglobal("purpleModeButtons");  if cb then cb:SetChecked(XyTrackerOptions.purpleModeEnabled and true or false) end
    cb = getglobal("hideLeftButtons");    if cb then cb:SetChecked(XyTrackerOptions.HideLeftMembers ~= false) end

    -- 请求同步信息以验证团长身份（发送同步信息者即为团长）
    if IsLeader then
        -- 团长发送同步请求（XyTrackerDeclaration 通常为 nil，回退到 playerDeclaration）
        SendAddonMessage("XY_SYNC_NEW", (XyTrackerDeclaration or playerDeclaration or ""), "RAID")
    else
        -- 非团长请求同步数据
        SendAddonMessage("XY_LOOTLIST_SYNC_REQUEST", "", "RAID")
    end
    
    -- 确保加载保存的宣言
    if not playerDeclaration or playerDeclaration == "" then
        playerDeclaration = XyTrackerDeclaration or ""
    end
    
    -- 宣言按钮显示控制
    if IsLeader then
        getglobal("XyTrackerFrameDeclarationButton"):Show()
        getglobal("XyTrackerFrameAnnounceDeclarationButton"):Show()
        -- 显示放弃权限按钮
        getglobal("XyTrackerFrameRelinquishButton"):Show()
    else
        getglobal("XyTrackerFrameDeclarationButton"):Hide()
        getglobal("XyTrackerFrameAnnounceDeclarationButton"):Hide()
        -- 隐藏放弃权限按钮
        getglobal("XyTrackerFrameRelinquishButton"):Hide()
    end
    
    -- 强制更新许愿权限拥有者显示
    XyTracker_UpdateLeaderText()
    
    -- 再次确保文本可见（冗余保障）
    local leaderText = getglobal("XyTrackerLeaderText")
    if leaderText and not leaderText:IsVisible() then
        leaderText:Show()
    end
    
    -- 宣言内容现在在独立窗口中管理，不需要在这里设置
    
    ShowUIPanel(XyTrackerFrame)
end

function XyTracker_HideXyWindow()
    HideUIPanel(XyTrackerFrame)
end

-- 创建小地图图标
-- 检查小地图按钮是否已被 MinimapButtonCollector 收进收纳条（收纳后父框架会被换成它的面板）
function XyTracker_IsMinimapButtonCollected()
    local button = getglobal("XyTrackerMinimapButton")
    local panel = getglobal("MinimapButtonCollectorPanel")
    if button and panel and button:GetParent() == panel then
        return true
    end
    return false
end

function XyTracker_CreateMinimapButton()
    -- 创建按钮框架
    local button = CreateFrame("Button", "XyTrackerMinimapButton", Minimap)
    button:SetFrameStrata("HIGH")
    button:SetWidth(32)  -- 按钮大小
    button:SetHeight(32)
    button:EnableMouse(true)
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton", "RightButton")  -- 同时支持左键和右键拖动
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")  -- 注册左键和右键点击事件
    
    -- 不设置基础背景，避免黑色背景
    button.icon = button:CreateTexture(nil, "ARTWORK")
    -- 图标：魔兽原版礼盒
    button.icon:SetTexture("Interface\\AddOns\\XyTracker\\Images\\icon.blp")
    -- 方形图标取 20px（对齐32框配20图比例），角才能藏进圆环内侧
    button.icon:SetWidth(20)
    button.icon:SetHeight(20)
    button.icon:SetPoint("CENTER", 0, 0)

    -- 边框圆环：对齐其他小地图按钮的标准样式
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border:SetWidth(53)
    button.border:SetHeight(53)
    button.border:SetPoint("TOPLEFT", 0, 0)
    
    -- 悬停高亮效果
    button:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
    local highlightTex = button:GetHighlightTexture()
    highlightTex:SetBlendMode("ADD")
    highlightTex:SetWidth(32)
    highlightTex:SetHeight(32)
    highlightTex:SetPoint("CENTER", 0, 0)
    
    -- 设置鼠标悬停提示
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetText("开启/关闭 许愿监视")
        GameTooltip:AddLine("左键点击显示/隐藏窗口", 1, 1, 1)
        GameTooltip:AddLine("左键拖动：围绕小地图移动", 1, 1, 1)
        GameTooltip:AddLine("右键拖动：自由移动（不受小地图限制）", 1, 1, 1)
        if XyTracker_IsMinimapButtonCollected() then
            -- 实际渲染尺寸 = 自然尺寸 × MBC 归一化缩放（随收纳条档位 24/28/32px 变化）
            local collectedSize = math.floor(button:GetWidth() * button:GetScale() + 0.5)
            GameTooltip:AddLine("已被收纳插件管理，尺寸跟随收纳条档位（当前 " .. collectedSize .. "px）", 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine("右键点击：放大/缩小图标", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- 设置拖动功能 - 支持左键围绕小地图拖动和右键自由拖动
    button:SetScript("OnDragStart", function()
        button.isDragging = true
        button.dragButton = arg1  -- 记录使用哪个按钮拖动
        
        if arg1 == "LeftButton" then
            -- 左键拖动：围绕小地图移动
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetScale()
            px = px / scale
            py = py / scale
            
            -- 计算角度并保持在小地图周围
            local angle = math.atan2(py - my, px - mx)
            local x = math.cos(angle) * 80
            local y = math.sin(angle) * 80
            
            -- 设置按钮位置
            button:ClearAllPoints()
            button:SetPoint("CENTER", Minimap, "CENTER", x, y)
        else
                -- 右键拖动：自由移动，不受小地图限制
                button:ClearAllPoints()
                -- 获取当前鼠标位置作为初始位置
                local px, py = GetCursorPosition()
                local scale = UIParent:GetScale()
                px = px / scale
                py = py / scale
                button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
        end
    end)
    
    button:SetScript("OnDragStop", function()
        -- 确保XyTrackerOptions表存在
        if not XyTrackerOptions then
            XyTrackerOptions = {}
        end
        
        -- 保存拖动类型
        local dragType = button.dragButton
        
        -- 只有在有拖动类型时才保存位置
        if dragType then
            -- 获取最终位置
            local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint()
            
            -- 根据拖动按钮类型保存到对应的变量并清除另一种类型的位置
            if dragType == "LeftButton" then
                -- 左键拖动：保存围绕小地图的位置
                -- 确保minimapPos始终是表类型
                if type(XyTrackerOptions.minimapPos) ~= "table" then
                    XyTrackerOptions.minimapPos = {}
                end
                XyTrackerOptions.minimapPos.x = xOfs
                XyTrackerOptions.minimapPos.y = yOfs
                XyTrackerOptions.freePos = nil -- 清除右键位置
                XyTrackerOptions.lastDragType = "LeftButton"
            else
                -- 右键拖动：保存自由位置
                XyTrackerOptions.freePos = {x = xOfs, y = yOfs}
                XyTrackerOptions.minimapPos = nil -- 清除左键位置
                XyTrackerOptions.lastDragType = "RightButton"
            end
        end
        
        -- 清除拖动状态
        button.isDragging = nil  -- 使用nil而不是false，与其他代码保持一致
        button.dragButton = nil
    end)
    
    -- 拖动更新逻辑
    button:SetScript("OnUpdate", function() 
        if button.isDragging then
            -- 确保XyTrackerOptions表存在
            if not XyTrackerOptions then
                XyTrackerOptions = {}
            end
            local px, py = GetCursorPosition()
            local scale = UIParent:GetScale()
            px = px / scale
            py = py / scale
            
            -- 保存当前拖动类型（避免在拖动过程中丢失）
            local currentDragType = button.dragButton or "LeftButton" -- 默认左键拖动
            
            if currentDragType == "LeftButton" then
                -- 左键拖动：围绕小地图移动
                local mx, my = Minimap:GetCenter()
                
                -- 计算角度并保持在小地图周围
                local angle = math.atan2(py - my, px - mx)
                local x = math.cos(angle) * 80
                local y = math.sin(angle) * 80
                
                -- 设置按钮位置
                button:ClearAllPoints()
                button:SetPoint("CENTER", Minimap, "CENTER", x, y)
                
                -- 立即保存左键拖动位置
                -- 确保minimapPos始终是表类型
                if type(XyTrackerOptions.minimapPos) ~= "table" then
                    XyTrackerOptions.minimapPos = {}
                end
                XyTrackerOptions.minimapPos.x = x
                XyTrackerOptions.minimapPos.y = y
                XyTrackerOptions.lastDragType = "LeftButton"
                XyTrackerOptions.freePos = nil -- 清除右键位置
            else
                -- 右键拖动：自由移动，不受小地图限制
                -- 直接设置按钮在屏幕上的绝对位置
                button:ClearAllPoints()
                button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
                
                -- 立即保存右键拖动位置
                -- 直接保存px, py，确保与设置位置时使用相同的值
                XyTrackerOptions.freePos = {x = px, y = py}
                XyTrackerOptions.lastDragType = "RightButton"
                XyTrackerOptions.minimapPos = nil -- 清除左键位置
            end
        end
    end)
    
    -- 应用图标尺寸：isLarge 为 true 放大到 44px，false 恢复 32px 默认尺寸
    local function ApplyIconSize(isLarge)
        local btnSize = isLarge and 44 or 32
        local texSize = isLarge and 27 or 20
        button:SetWidth(btnSize)
        button:SetHeight(btnSize)
        local normalTex = button.icon
        if normalTex then
            normalTex:SetWidth(texSize)
            normalTex:SetHeight(texSize)
        end
        local highlightTex = button:GetHighlightTexture()
        if highlightTex then
            highlightTex:SetWidth(btnSize)
            highlightTex:SetHeight(btnSize)
        end
        -- 边框圆环随尺寸档缩放（32→53，44→73）
        if button.border then
            button.border:SetWidth(isLarge and 73 or 53)
            button.border:SetHeight(isLarge and 73 or 53)
        end
        -- 保存图标大小状态
        XyTrackerOptions.iconSize = btnSize
    end

    -- 修改点击事件
    button:SetScript("OnClick", function()
        -- 检查是否是拖动操作而不是纯点击
    
        if not button.isDragging then
            -- 右键点击：放大缩小图标
            if arg1 == "RightButton" then
                -- 被 MinimapButtonCollector 收纳时关闭放大缩小，尺寸由收纳条按档位归一化（24/28/32px）
                -- 注意：收纳后不能改按钮自然尺寸（会让 MBC 的归一化计算失准），贴图补偿由定时检查处理
                if XyTracker_IsMinimapButtonCollected() then
                    -- 实际渲染尺寸 = 自然尺寸 × MBC 归一化缩放
                    local collectedSize = math.floor(button:GetWidth() * button:GetScale() + 0.5)
                    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 图标已被 MinimapButtonCollector 收纳，放大缩小不可用，尺寸跟随收纳条档位（当前 " .. collectedSize .. "px）")
                else
                    -- 切换按钮尺寸
                    -- 使用math.floor解决浮点数精度问题
                    local currentWidth = math.floor(button:GetWidth())
                    if currentWidth == 32 then
                        -- 放大
                        ApplyIconSize(true)
                    else
                        -- 缩小回原始尺寸
                        ApplyIconSize(false)
                    end
                end
            -- 左键点击：显示/隐藏窗口
            elseif arg1 == "LeftButton" then
                if XyTrackerFrame:IsShown() then
                    XyTracker_HideXyWindow()
                else
                    XyTracker_ShowXyWindow()
                end
            end
        else
            -- 拖动操作后的尺寸保持
            -- 使用math.floor解决浮点数精度问题
            local currentWidth = math.floor(button:GetWidth())
            if currentWidth ~= 32 and currentWidth ~= 44 then
                button:SetWidth(32)
                button:SetHeight(32)
                local normalTex = button.icon
                if normalTex then
                    normalTex:SetWidth(20)
                    normalTex:SetHeight(20)
                end
                -- 边框圆环恢复 32 档尺寸
                if button.border then
                    button.border:SetWidth(53)
                    button.border:SetHeight(53)
                end
                local highlightTex = button:GetHighlightTexture()
                if highlightTex then
                    highlightTex:SetWidth(32)
                    highlightTex:SetHeight(32)
                end
            end
        end
    end)
    
    -- 设置初始位置
    -- 确保XyTrackerOptions表存在并初始化必要字段
    if not XyTrackerOptions then
        XyTrackerOptions = {}
    end
    
    -- 加载保存的图标大小（小档现为 32，旧存档的 26/36 统一归并到 32；44 档不变）
    if XyTrackerOptions.iconSize then
        local size = XyTrackerOptions.iconSize == 44 and 44 or 32
        XyTrackerOptions.iconSize = size
        button:SetWidth(size)
        button:SetHeight(size)
        local normalTex = button.icon
        if normalTex then
            normalTex:SetWidth(size == 32 and 20 or 27)
            normalTex:SetHeight(size == 32 and 20 or 27)
        end
        -- 边框圆环随尺寸档缩放
        if button.border then
            button.border:SetWidth(size == 32 and 53 or 73)
            button.border:SetHeight(size == 32 and 53 or 73)
        end
        local highlightTex = button:GetHighlightTexture()
        if highlightTex then
            highlightTex:SetWidth(size)
            highlightTex:SetHeight(size)
        end
    end
    -- 根据最后一次拖动类型加载对应的位置
    -- 添加额外的验证确保数据有效
    if XyTrackerOptions.lastDragType == "RightButton" and XyTrackerOptions.freePos and 
       XyTrackerOptions.freePos.x and XyTrackerOptions.freePos.y then
        -- 移除所有坐标限制，允许图标自由拖动到任何位置
        local x, y = XyTrackerOptions.freePos.x, XyTrackerOptions.freePos.y
        
        -- 右键拖动模式：直接使用保存的坐标，保持与保存时完全一致的锚点设置
        -- 不再添加额外偏移，因为保存时已经使用了相同的锚点类型
        button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    elseif XyTrackerOptions.minimapPos and XyTrackerOptions.minimapPos.x and XyTrackerOptions.minimapPos.y then
        -- 左键拖动模式：使用围绕小地图的位置
        button:SetPoint("CENTER", Minimap, "CENTER", XyTrackerOptions.minimapPos.x, XyTrackerOptions.minimapPos.y)
    else
        -- 默认位置（小地图右侧）
        button:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
    end
    
    -- 保存按钮引用并确保显示
    XyTrackerMinimapButton = button
    button:Show()
    
    -- 添加错误处理，确保按钮始终可见
    local errorCheckFrame = CreateFrame("Frame")
    local lastCheckTime = 0
    errorCheckFrame:SetScript("OnUpdate", function()
        -- 每5秒检查一次按钮是否可见
        local currentTime = GetTime()
        if not lastCheckTime or currentTime - lastCheckTime > 5 then
            lastCheckTime = currentTime
            local normalTex = button.icon
            local wantTex = (XyTrackerOptions.iconSize == 44) and 27 or 20
            if normalTex and math.floor(normalTex:GetWidth()) ~= wantTex then
                normalTex:SetWidth(wantTex)
                normalTex:SetHeight(wantTex)
            end
            if XyTrackerMinimapButton and not XyTrackerMinimapButton:IsVisible() then
                XyTrackerMinimapButton:Show()
                -- 如果位置无效，重置到默认位置
                if XyTrackerOptions then
                    -- 检查右键拖动位置是否无效（仅检查数据结构有效性，移除坐标范围限制）
                    local freePosInvalid = XyTrackerOptions.lastDragType == "RightButton" and
                                         (not XyTrackerOptions.freePos or
                                          not XyTrackerOptions.freePos.x or
                                          not XyTrackerOptions.freePos.y)
                    
                    -- 检查左键拖动位置是否无效
                    local minimapPosInvalid = XyTrackerOptions.lastDragType == "LeftButton" and 
                                             (not XyTrackerOptions.minimapPos or 
                                              not XyTrackerOptions.minimapPos.x or 
                                              not XyTrackerOptions.minimapPos.y or 
                                              math.abs(XyTrackerOptions.minimapPos.x) > 200 or 
                                              math.abs(XyTrackerOptions.minimapPos.y) > 200)
                    
                    -- 根据当前拖动类型检查对应位置是否有效
                    if freePosInvalid or minimapPosInvalid then
                        -- 重置为默认位置（使用左键拖动模式）
                        XyTrackerOptions.minimapPos = {x = 80, y = 0}
                        XyTrackerOptions.freePos = nil
                        XyTrackerOptions.lastDragType = "LeftButton"
                        XyTrackerMinimapButton:ClearAllPoints()
                        XyTrackerMinimapButton:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
                        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 小地图图标位置无效，已重置到默认位置")
                    end
                end
            end
        end
    end)
end

-- 简化的位置更新函数，用于兼容旧版代码
function XyButton_UpdatePosition()
    -- 使用新的位置加载逻辑，与创建按钮时保持一致
    if XyTrackerMinimapButton and XyTrackerOptions then
        XyTrackerMinimapButton:ClearAllPoints()
        
        -- 根据最后一次拖动类型加载对应的位置
        if XyTrackerOptions.lastDragType == "RightButton" and XyTrackerOptions.freePos and 
           XyTrackerOptions.freePos.x and XyTrackerOptions.freePos.y then
            -- 移除所有坐标限制，允许图标自由拖动到任何位置
            local x, y = XyTrackerOptions.freePos.x, XyTrackerOptions.freePos.y
            
            -- 右键拖动模式：直接使用保存的坐标，保持与保存时完全一致的锚点设置
            XyTrackerMinimapButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        elseif XyTrackerOptions.minimapPos and XyTrackerOptions.minimapPos.x and XyTrackerOptions.minimapPos.y then
            -- 左键拖动模式
            XyTrackerMinimapButton:SetPoint("CENTER", Minimap, "CENTER", XyTrackerOptions.minimapPos.x, XyTrackerOptions.minimapPos.y)
        else
            -- 默认位置
            XyTrackerMinimapButton:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
        end
    end
end


-- 检测聊天中的物品链接并通报许愿信息
-- 性能：许愿解析结果缓存。按许愿字符串内容缓存，内容相同则解析结果必然相同，无需失效处理
local XYT_WishParseCache = {}
function XYT_ParseWishCached(xy)
    local cached = XYT_WishParseCache[xy]
    if cached then
        return cached.primary, cached.all
    end
    local success, primaryWishItem, allWishItems = pcall(ExtractItemName, xy)
    if not success or type(primaryWishItem) ~= "string" or primaryWishItem == "" then
        primaryWishItem = ""
        allWishItems = {}
    end
    XYT_WishParseCache[xy] = {primary = primaryWishItem, all = allWishItems}
    return primaryWishItem, allWishItems
end

-- 构建当前团队成员名单（名字→true）。离队成员的许愿仍留在 XyArray 里（按"隐藏离队人员"选项隐藏或灰色显示），
-- 重复警报和自动查询播报前都要用它过滤，只统计在团人员
function XYT_BuildRaidMemberSet()
    local members = {}
    local totalMembers = GetNumRaidMembers()
    if totalMembers and totalMembers > 0 then
        for i = 1, totalMembers do
            local name = GetRaidRosterInfo(i)
            if name then
                members[name] = true
            end
        end
    end
    return members
end

function CheckItemAndAnnounceWish(msg, sender)
    -- 安全检查：确保参数有效
   
    if not msg or type(msg) ~= "string" then
        return
    end
    
    if not XyTrackerOptions.AutoAnnounce then 
        return 
    end  -- 只有在启用自动播报时才处理，移除XyInProgress条件，允许停止许愿后也能播报
    
    -- 检查消息是否包含白名单标记"★播报许愿★"，如果是则不进行处理
    if string.find(msg, "★播报许愿★") then
        return
    end
    
    -- 获取当前玩家名称
    local playerName = UnitName("player")
    
    -- 提取消息中的所有物品链接
    local itemLinkFound = false
    
    -- 先收集所有物品链接
    local allItemLinks = {}
    for itemLink in string.gmatch(msg, "|Hitem:.-|h.-|h") do
        table.insert(allItemLinks, itemLink)
    end
    
    -- 逐个处理每个物品链接
    for itemIndex, itemLink in ipairs(allItemLinks) do
        itemLinkFound = true
        
        -- 使用pcall安全调用ExtractItemName函数
        local success, itemName = pcall(ExtractItemName, itemLink)
        if not success or type(itemName) ~= "string" then
            itemName = "" -- 设置为空字符串以避免错误
        end
        
        -- 使用全局的安全字符串清理函数
        local cleanItemName = safeCleanString(itemName)
        
        -- 判断是团长还是队员，执行不同的播报逻辑
        if IsLeader then
            -- 团长逻辑：显示所有实际许愿的玩家
            local wishPlayers = {}
            
            -- 遍历许愿列表，匹配有效许愿条目
            for i = 1, table.getn(XyArray) do
                local info = XyArray[i]
                if info and info["name"] and info["xy"] and info["xy"] ~= "---未许愿---" then
                    -- 使用许愿解析缓存获取主物品名称和所有物品名称列表（同一许愿字符串只解析一次）
                    local primaryWishItem, allWishItems = XYT_ParseWishCached(info["xy"])
                    
                    -- 使用安全的字符串清理函数处理主物品名称
                    local cleanPrimaryWishItem = safeCleanString(primaryWishItem)
                    
                    -- 标记是否匹配成功
                    local isMatched = false
                    
                    -- 修复：添加物品名称有效性检查，避免空值或无效值导致的误判
                    if primaryWishItem ~= "" and cleanPrimaryWishItem ~= "" and cleanItemName ~= "" then
                        -- 先检查主物品名称是否匹配
                        -- 修复：只使用严格的相等比较，移除模糊匹配条件
                        local matchCondition1 = cleanPrimaryWishItem == cleanItemName
                        local matchCondition2 = primaryWishItem == itemName
                        
                        if matchCondition1 or matchCondition2 then
                            isMatched = true
                        else
                            -- 如果主物品不匹配，检查其他物品名称
                            if type(allWishItems) == "table" and table.getn(allWishItems) > 1 then
                                for _, wishItem in ipairs(allWishItems) do
                                    local cleanWishItem = safeCleanString(wishItem)
                                    
                                    -- 修复：同样只使用严格的相等比较
                                    if cleanWishItem == cleanItemName or wishItem == itemName then
                                        isMatched = true
                                        break -- 一旦匹配成功，就跳出循环
                                    end
                                end
                            end
                        end
                    end
                    
                    -- 如果匹配成功，添加到许愿玩家列表
                    if isMatched then
                        table.insert(wishPlayers, {name = info["name"], dkp = info["dkp"]})
                    end
                end
            end
            
            -- 为当前物品生成团长通报内容
            if type(wishPlayers) == "table" then
                -- 获取当前团队成员列表（离队灰色成员不参与播报）
                local currentRaidMembers = XYT_BuildRaidMemberSet()
                
                -- 只保留当前在团队中的玩家
                local inRaidWishPlayers = {}
                for idx = 1, table.getn(wishPlayers) do
                    local player = wishPlayers[idx]
                    if type(player) == "table" then
                        local name = player.name or "未知"
                        if currentRaidMembers[name] then
                            table.insert(inRaidWishPlayers, player)
                        end
                    end
                end
                
                if table.getn(inRaidWishPlayers) > 0 then
                    local announcement = "★"..cleanItemName.."★共"..table.getn(inRaidWishPlayers).."人许愿："
                    for idx = 1, table.getn(inRaidWishPlayers) do
                        local player = inRaidWishPlayers[idx]
                        if type(player) == "table" then
                            local name = player.name or "未知"
                            local dkp = player.dkp or "0"
                            announcement = announcement .. name .. "（" .. dkp .. "分）"
                            if idx < table.getn(inRaidWishPlayers) then
                                announcement = announcement .. "、"
                            end
                        end
                    end
                    
                    local currentLanguage = GetDefaultLanguage("player")
                    SendChatMessage(announcement, "RAID", currentLanguage, nil)
                end
            end
        else
            -- 队员逻辑：只显示自己是否许愿了该物品
            -- 修复：确保每次检查都重新初始化为false
            local hasWished = false
            local myDkp = "0"
            
            -- 遍历许愿列表，检查自己是否许愿了该物品
            for i = 1, table.getn(XyArray) do
                local info = XyArray[i]
                if info and info["name"] == playerName and info["xy"] and info["xy"] ~= "---未许愿---" then
                    -- 使用许愿解析缓存（同一许愿字符串只解析一次）
                    local primaryWishItem, allWishItems = XYT_ParseWishCached(info["xy"])
                    
                    -- 使用安全的字符串清理函数处理主物品名称
                    local cleanPrimaryWishItem = safeCleanString(primaryWishItem)
                    
                    -- 检查是否匹配
                    local isMatched = false
                    
                    -- 修复：添加物品名称有效性检查，避免空值或无效值导致的误判
                    if primaryWishItem ~= "" and cleanPrimaryWishItem ~= "" and cleanItemName ~= "" then
                        -- 使用更严格的匹配条件，避免模糊匹配导致的误判
                        if cleanPrimaryWishItem == cleanItemName or primaryWishItem == itemName then
                            isMatched = true
                        else
                            -- 如果主物品不匹配，检查其他物品名称
                            if type(allWishItems) == "table" and table.getn(allWishItems) > 1 then
                                for _, wishItem in ipairs(allWishItems) do
                                    local cleanWishItem = safeCleanString(wishItem)
                                    
                                    -- 同样使用严格匹配
                                    if cleanWishItem == cleanItemName or wishItem == itemName then
                                        isMatched = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    if isMatched then
                        hasWished = true
                        myDkp = info["dkp"] or "0"
                        break
                    end
                end
            end
            
            -- 为当前物品生成队员通报内容
            if hasWished then
                local announcement = "★"..cleanItemName.."★我已许愿（"..myDkp.."分）"
                local currentLanguage = GetDefaultLanguage("player")
                SendChatMessage(announcement, "RAID", currentLanguage, nil)
            end
        end
    end
    
    -- 如果没有找到物品链接，尝试直接匹配物品名称
    if not itemLinkFound then
        local directCleanItemName = safeCleanString(msg)
        
        -- 获取当前玩家名称
        local playerName = UnitName("player")
        
        -- 判断是团长还是队员，执行不同的播报逻辑
        if IsLeader then
            -- 团长逻辑：显示所有实际许愿的玩家
            local directWishPlayers = {}
            for i = 1, table.getn(XyArray) do
                local info = XyArray[i]
                if info and info["xy"] and info["xy"] ~= "---未许愿---" then
                    -- 使用许愿解析缓存（同一许愿字符串只解析一次）
                    local wishItem = XYT_ParseWishCached(info["xy"])
                    if wishItem ~= "" and wishItem ~= "---未许愿---" then
                        
                        local cleanWishItem = safeCleanString(wishItem)
                        
                        if (cleanWishItem == directCleanItemName or wishItem == msg) then
                            table.insert(directWishPlayers, {name = info["name"], dkp = info["dkp"]})
                        end
                    end
                end
            end
            
            if type(directWishPlayers) == "table" then
                -- 获取当前团队成员列表（离队灰色成员不参与播报）
                local currentRaidMembers = XYT_BuildRaidMemberSet()
                
                -- 只保留当前在团队中的玩家
                local inRaidDirectWishPlayers = {}
                for idx = 1, table.getn(directWishPlayers) do
                    local player = directWishPlayers[idx]
                    if type(player) == "table" then
                        local name = player.name or "未知"
                        if currentRaidMembers[name] then
                            table.insert(inRaidDirectWishPlayers, player)
                        end
                    end
                end
                
                if table.getn(inRaidDirectWishPlayers) > 0 then
                    local announcement = "★"..directCleanItemName.."★共"..table.getn(inRaidDirectWishPlayers).."人许愿："
                    for idx = 1, table.getn(inRaidDirectWishPlayers) do
                        local player = inRaidDirectWishPlayers[idx]
                        if type(player) == "table" then
                            local name = player.name or "未知"
                            local dkp = player.dkp or "0"
                            announcement = announcement .. name .. "（" .. dkp .. "分）"
                            if idx < table.getn(inRaidDirectWishPlayers) then
                                announcement = announcement .. "、"
                            end
                        end
                    end
                    
                    local currentLanguage = GetDefaultLanguage("player")
                    SendChatMessage(announcement, "RAID", currentLanguage, nil)
                end
            end
        else
            -- 队员逻辑：只显示自己是否许愿了该物品
            -- 修复：确保每次检查都重新初始化为false
            local hasWished = false
            local myDkp = "0"
            
            for i = 1, table.getn(XyArray) do
                local info = XyArray[i]
                if info and info["name"] == playerName and info["xy"] and info["xy"] ~= "---未许愿---" then
                    -- 使用许愿解析缓存（同一许愿字符串只解析一次）
                    local wishItem = XYT_ParseWishCached(info["xy"])
                    if wishItem ~= "" and wishItem ~= "---未许愿---" then
                        
                        local cleanWishItem = safeCleanString(wishItem)
                        
                        -- 修复：添加directCleanItemName空值检查，确保使用严格的相等比较
                        if directCleanItemName ~= "" and (cleanWishItem == directCleanItemName or wishItem == msg) then
                            hasWished = true
                            myDkp = info["dkp"] or "0"
                            break
                        end
                    end
                end
            end
            
            if hasWished then
                local announcement = "★"..directCleanItemName.."★我已许愿（"..myDkp.."分）"
                local currentLanguage = GetDefaultLanguage("player")
                SendChatMessage(announcement, "RAID", currentLanguage, nil)
            end
        end
    end
end






-- 用于跟踪已接收的拾取信息，防止重复处理
local recentLootMessages = {}

-- 检测是否为重复的拾取信息（10秒内）
function XyTracker_IsDuplicateLoot(msg)
    if not msg or msg == "" then
        return false
    end
    
    local currentTime = GetTime()
    
    -- 清理过期的记录（超过10秒）
    for storedMsg, timestamp in pairs(recentLootMessages) do
        if currentTime - timestamp > 10 then
            recentLootMessages[storedMsg] = nil
        end
    end
    
    -- 检查是否有重复
    if recentLootMessages[msg] then
        return true-- 消息相同，返回false
    end
    -- 添加新记录
    recentLootMessages[msg] = currentTime
    return false -- 消息不同，返回true
end

-- 修改：接收其他团队成员的拾取同步信息
function XyTracker_ReceiveLootSync(syncMsg, senderName)
    if not syncMsg or syncMsg == "" then
        return
    end
    
    -- 解析同步消息：玩家名称:原始拾取消息
    local playerName, originalMessage = string.match(syncMsg, "(.-):(.*)")
    local itemLink, timeStr
    if playerName and originalMessage then
        -- 从原始拾取消息中提取物品链接（格式：|cff..|Hitem:..|h[名称]|h|r）
        itemLink = string.match(originalMessage, "(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")
    end
    if not (playerName and itemLink) then
        -- 尝试解析旧格式的消息作为兼容（玩家:物品:时:分）
        local oldPlayer, oldItem, oldHour, oldMinute = string.match(syncMsg, "(.-):(.-):(.-):(.-)")
        if oldPlayer and oldItem then
            playerName = oldPlayer
            itemLink = oldItem
            timeStr = oldHour .. ":" .. oldMinute
        else
            return -- 消息格式错误
        end
    end
    -- 修复：hour/minute 此前未赋值就被使用；优先取旧格式时间，否则用接收时的本地时间
    local hour, minute
    if timeStr then
        local h, m = string.match(timeStr, "(%d+):(%d+)")
        hour = tonumber(h)
        minute = tonumber(m)
    end
    if not hour or not minute then
        hour = tonumber(date("%H"))
        minute = tonumber(date("%M"))
    end
        
    -- 队员接收团长的完整同步信息，直接处理
    local extractedItemLink = itemLink
    
    -- 提取物品名称
    local itemName
    if extractedItemLink then
        itemName = string.match(extractedItemLink, "|h%[([^%]]+)%]|h") or extractedItemLink
    else
        itemName = itemLink
        -- 如果没有物品链接，创建一个模拟的链接
        extractedItemLink = "|cff0070dd|Hitem:0:0:0:0:0:0:0:0|h[" .. itemName .. "]|h|r"
    end
    
    -- 记录到拾取列表
    local info = getXyInfo(playerName)
    local isWishItem = false
    
    if info and info["xy"] and info["xy"] ~= "---未许愿---" then
        local success, primaryWishItem, allWishItems = pcall(ExtractItemName, info["xy"])
        if success then
            local function cleanString(str)
                if not str then return "" end
                str = string.gsub(str, "|c%x+", "")
                str = string.gsub(str, "|r", "")
                str = string.gsub(str, "%[([^%]]+)%]", "%1")
                str = string.lower(str)
                return str
            end
            
            local cleanItemName = cleanString(itemName)
            
            if primaryWishItem and primaryWishItem ~= "" then
                local cleanPrimaryWishItem = cleanString(primaryWishItem)
                if cleanPrimaryWishItem == cleanItemName or primaryWishItem == itemName or string.find(cleanPrimaryWishItem, cleanItemName, 1, true) or string.find(cleanItemName, cleanPrimaryWishItem, 1, true) then
                    isWishItem = true
                end
            end
            
            if not isWishItem and type(allWishItems) == "table" and table.getn(allWishItems) > 0 then
                for _, wishItem in ipairs(allWishItems) do
                    local cleanWishItem = cleanString(wishItem)
                    if cleanWishItem == cleanItemName or wishItem == itemName or string.find(cleanWishItem, cleanItemName, 1, true) or string.find(cleanItemName, cleanWishItem, 1, true) then
                        isWishItem = true
                        break
                    end
                end
            end
        end
    end
    
    -- 提取物品信息来自动补齐分数和事件
    local itemID = ExtractItemID(extractedItemLink)
    local points = 0 -- 默认0分
    
    -- 如果物品信息可获取，尝试自动计算分数
    if itemID then
        local itemName, itemLink, quality, level, minLevel, type, subType, maxStack, equipLoc, texture, vendorPrice = GetItemInfo(itemID)
        if quality then
            -- 根据物品品质设置默认分数
            if quality >= 4 then -- 史诗
                points = 20
            elseif quality == 3 then -- 精良
                points = 10
            elseif quality == 2 then -- 优秀
                points = 5
            end
        end
    end
    
    -- 创建物品数据对象
    local lootItem = {
        itemName = tostring(itemName),
        itemLink = extractedItemLink and tostring(extractedItemLink) or "",
        playerName = playerName and tostring(playerName) or "未知玩家",
        points = points, -- 根据物品品质自动补齐分数
        isWish = isWishItem,
        timestamp = {
            hour = hour,
            minute = minute
        }
    }
    
    -- 添加到LootList并更新UI
    lootItem.timestamp = time() -- 添加时间戳
    table.insert(LootList, lootItem)
    XyTracker_UpdateLootList()
    
    -- 处理拾取分配信息
    local assignment = {
        itemName = itemName,
        playerName = playerName,
        confirmed = true,
        timestamp = {hour = hour, minute = minute}
    }
    

end





-- 检测聊天中的物品链接并通报许愿信息


    -- 检测物品获取
    function XyTracker_CHATMSGLOOT(msg)
        local player, itemLink = string.match(msg, "(.+)获得了物品：(.+)。")
        if player and itemLink then    
            -- 非团长玩家检测到拾取信息时，发送同步消息给团长
            if not IsLeader then
                -- 构建同步消息：原始拾取消息
                local syncMsg =  msg
                -- 发送同步消息到插件通讯频道（队员发送给团长）
                SendAddonMessage("XY_MEMBER_LOOT", syncMsg, "RAID")
            end
            
            -- 当玩家自己获得物品且有权限时，也处理许愿完成逻辑
            local isSelfLoot = player == UnitName("player")
            
            -- 先取拾取前的许愿内容：下方自动扣分块可能先把许愿标记为已完成，
            -- 后面判断"拾取物品是否为许愿物品"时再用 info["xy"] 会匹配不到
            local preLootInfo = getXyInfo(player)
            local preLootWish = preLootInfo and preLootInfo["xy"] or nil
            
            -- 先处理自动扣分逻辑（如果需要）
            if XyTrackerOptions.autoMinDkp then
            -- 检查该玩家是否在1分钟内发过言
            local currentTime = GetTime()
                local playerMessage = raidMessages[player]
            
            if playerMessage and (currentTime - playerMessage.timestamp) <= 60 then
                    local _, _, itemColor = string.find(itemLink, "|c(%x+)|H")
                    local shouldDeduct = false
                    
                    if itemColor == "ffa335ee" and XyTrackerOptions.purpleModeEnabled then
                        shouldDeduct = true
                    elseif itemColor == "ff0070dd" and XyTrackerOptions.blueModeEnabled then
                        shouldDeduct = true
                    elseif itemColor == "ff1eff00" and XyTrackerOptions.greenModeEnabled then
                        shouldDeduct = true
                    end
                    
                    if shouldDeduct and (IsLeader or isSelfLoot) then  -- 团长或自己获得物品时都处理
                        local info = getXyInfo(player)
                        if info then
                            local number = playerMessage.message
                            
                            -- 自动扣分新规则：0分不扣分只尝试完成许愿；1-4分直接扣；5分需物品与许愿一致才免扣；6分及以上标记完成并扣(出价-5)分
                            local actualDeducted = 0 -- 实际扣除的分数（供拾取列表显示）

                            if info["xy"] and string.find(info["xy"], "已完成许愿") then
                                -- 已完成许愿状态，直接扣分（保留既有分支；子串匹配兼容两种已完成格式）
                                actualDeducted = number
                                info["dkp"] = (tonumber(info["dkp"]) or 0) - number
                                SendChatMessage(player .. " 扣除" .. number .. "分，当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                            elseif info["xy"] and info["xy"] ~= "---未许愿---" then
                                -- 提取物品名称（用于匹配）
                                local itemName = string.match(itemLink, "|h%[(.-)%]|h")
                                if not itemName then
                                    itemName = itemLink -- 如果无法提取物品名称，使用整个链接
                                end

                                if number == 0 then
                                    -- 出0分：不扣分，调用MarkItemAsCompleted尝试完成许愿（物品与许愿匹配才实际变化）
                                    local newWish = MarkItemAsCompleted(info["xy"], itemName)
                                    if newWish ~= info["xy"] then
                                        info["xy"] = newWish
                                        SendChatMessage(player .. " 已完成当前物品许愿，当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                                    else
                                        SendChatMessage(player .. " 出0分，无需扣分，当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                                    end
                                elseif number <= 4 then
                                    -- 出1-4分：直接扣除相应分数
                                    actualDeducted = number
                                    info["dkp"] = (tonumber(info["dkp"]) or 0) - number
                                    SendChatMessage(player .. " 扣除" .. number .. "分，当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                                elseif number == 5 then
                                    -- 出5分：物品与许愿一致则不扣分并标记完成，否则扣5分
                                    local newWish = MarkItemAsCompleted(info["xy"], itemName)
                                    if newWish ~= info["xy"] then
                                        info["xy"] = newWish
                                        SendChatMessage(player .. " 已完成当前物品许愿（出5分），当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                                    else
                                        actualDeducted = 5
                                        info["dkp"] = (tonumber(info["dkp"]) or 0) - 5
                                        SendChatMessage(player .. " 出5分但物品与许愿不符，扣除5分，当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                                    end
                                else
                                    -- 出6分及以上：标记许愿完成并扣除(出价-5)分
                                    local newWish = MarkItemAsCompleted(info["xy"], itemName)
                                    if newWish ~= info["xy"] then
                                        info["xy"] = newWish
                                    end
                                    actualDeducted = number - 5
                                    info["dkp"] = (tonumber(info["dkp"]) or 0) - actualDeducted
                                    SendChatMessage(player .. " 已完成当前物品许愿，并扣除" .. actualDeducted .. "分（出" .. number .. "分-5分），当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                                end
                            end
                            
                            XyTracker_UpdateList()
                            syncXy(player) -- 只同步该玩家

                            -- 只清除获得物品玩家的发言记录
                            raidMessages[player] = nil
                            
                            -- 保存实际扣除的分数以便在拾取列表中显示
                            local deductedPoints = actualDeducted
                            
                            -- 存储在临时变量中，供下面的拾取列表使用
                            if not tempDeductedPoints then
                                tempDeductedPoints = {}
                            end
                            tempDeductedPoints[player] = deductedPoints
                        end
                    end
                end
            end
            
            -- 记录所有拾取的物品到拾取列表，无论是否花费分数
            local itemName = string.match(itemLink, "|h%[([^%]]+)%]|h")
            if itemName then
                -- 获取玩家信息
                local info = getXyInfo(player)
                
                -- 确定物品是否为许愿物品（用拾取前捕获的许愿内容匹配，此时可能已被标为已完成）
                local isWishItem = false
                local wishForMatch = preLootWish or (info and info["xy"])
                if wishForMatch and wishForMatch ~= "---未许愿---" then
                    -- 使用ExtractItemName检查玩家是否许愿了当前物品
                    local success, primaryWishItem, allWishItems = pcall(ExtractItemName, wishForMatch)
                    if success then
                        -- 简单清理物品名称（去掉多余字符）
                        local function cleanString(str)
                            if not str then return "" end
                            str = string.gsub(str, "|c%x+", "")
                            str = string.gsub(str, "|r", "")
                            str = string.gsub(str, "%[([^%]]+)%]", "%1")
                            str = string.lower(str)
                            return str
                        end
                        
                        local cleanItemName = cleanString(itemName)
                        
                        -- 检查主物品名称是否匹配
                        if primaryWishItem and primaryWishItem ~= "" then
                            local cleanPrimaryWishItem = cleanString(primaryWishItem)
                            if cleanPrimaryWishItem == cleanItemName or primaryWishItem == itemName or string.find(cleanPrimaryWishItem, cleanItemName, 1, true) or string.find(cleanItemName, cleanPrimaryWishItem, 1, true) then
                                isWishItem = true
                            end
                        end
                        
                        -- 如果主物品不匹配，检查其他物品名称
                        if not isWishItem and type(allWishItems) == "table" and table.getn(allWishItems) > 0 then
                            for _, wishItem in ipairs(allWishItems) do
                                local cleanWishItem = cleanString(wishItem)
                                if cleanWishItem == cleanItemName or wishItem == itemName or string.find(cleanWishItem, cleanItemName, 1, true) or string.find(cleanItemName, cleanWishItem, 1, true) then
                                    isWishItem = true
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- 确定扣除的分数（如果有）
                local pointsUsed = 0
                if tempDeductedPoints and tempDeductedPoints[player] then
                    pointsUsed = tempDeductedPoints[player]
                    -- 清除临时存储的分数，避免影响其他物品
                    tempDeductedPoints[player] = nil
                end
                
                -- 如果是许愿物品，无论玩家是否打数字，都自动标记为已许愿
                if isWishItem and info and info["xy"] and info["xy"] ~= "---未许愿---" and not string.find(info["xy"], "已完成许愿") then
                    -- 调用MarkItemAsCompleted函数更新许愿状态
                    local newWish = MarkItemAsCompleted(info["xy"], itemName)
                    
                    -- 如果许愿状态发生变化
                    if newWish ~= info["xy"] then
                        info["xy"] = newWish
                        
                        -- 无论是否打数字，只要是许愿物品就发送已完成许愿的消息
                        -- 团长或自己获得物品时都发送消息
                        if XyTrackerOptions.AutoAnnounce and (IsLeader or isSelfLoot) then
                            SendChatMessage(player .. " 已完成当前物品许愿，当前剩余分数：[" .. info["dkp"] .. "]", "RAID", this.language, nil)
                        end
                        -- 更新列表
                        XyTracker_UpdateList()
                        -- 只有团长同步数据（只同步该玩家）
                        if IsLeader then
                            syncXy(player)
                        end
                    end
                end
                

                    -- 只有在有IsLeader信息的情况下才自动记录拾取列表
                if IsLeader ~= nil then
                    -- 加强数据验证和类型转换，确保添加的物品数据格式正确
                   -- 使用本地时间而非服务器时间
                    local hour, minute = tonumber(date("%H")), tonumber(date("%M"))
                    
                    -- 确保player是有效的字符串
                    local validPlayerName = player and tostring(player) or "未知玩家"
                    
                    -- 创建物品数据对象，确保所有字段类型正确
                    local lootItem = {
                        itemName = tostring(itemName),
                        itemLink = itemLink and tostring(itemLink) or "",
                        playerName = validPlayerName,
                        points = type(pointsUsed) == "number" and pointsUsed or 0,
                        isWish = type(isWishItem) == "boolean" and isWishItem or false,
                        timestamp = {
                            hour = type(hour) == "number" and hour or 0,
                            minute = type(minute) == "number" and minute or 0
                        }
                    }
                    
                    -- 所有玩家都执行本地物品拾取逻辑，确保自己拾取的物品能被正常记录
                    -- 添加到LootList并更新UI
                    lootItem.timestamp = time() -- 添加时间戳
                    table.insert(LootList, lootItem)
                    
                    -- 更新拾取列表UI
                    XyTracker_UpdateLootList()
                    if IsLeader then
                        -- 传递当前lootItem对象，确保发送正确的物品信息
                        syncLootList(true, lootItem)
                    end
                end
            end
        end
    end
-- 取团队职务（0=团员 1=助理 2=团长），不在团队或未找到返回nil
function XyTracker_GetRaidRank(name)
    if not name then return nil end
    for i = 1, GetNumRaidMembers() do
        local n, rank = GetRaidRosterInfo(i)
        if n == name then return rank end
    end
    return nil
end

-- 供备份模块读取当前许愿团长（LeaderName 是本文件局部变量，外部文件不可见）
function XyTracker_GetLeaderName()
    return LeaderName or ""
end

-- 许愿同步来源校验：只接受"当前认定的许愿团长"或"真实团长(rank 2)"的XY_START/XY_SYNC。
-- 自带n=清表头导致许愿表被反复清空的问题
function XyTracker_ShouldAcceptLeader(sender)
    if not sender or sender == "" then return false end
    if sender == UnitName("player") then return false end
    if XyTracker_GetRaidRank(sender) == 2 then return true end
    if not LeaderName or LeaderName == "" then return true end
    if sender == LeaderName then return true end
    return false
end

function XyTracker_OnEvent(event)
	-- 处理变量加载完成事件，确保在所有保存的变量加载后执行
	if event == "VARIABLES_LOADED" then
		XyTracker_LoadCustomStarttext()
		-- 确保斜杠命令已注册
		SlashCmdList["XYTRACKER"] = XyTracker_OnSlashCommand
		
		-- 初始化XyTrackerOptions，确保重载后正确保存
		InitializeXyTrackerOptions()
		
-- 初始化CML变量
CML_Vars = CML_Vars or {};
CML_Vars.Enabled = CML_Vars.Enabled or true;
CML_Vars.PostRandom = CML_Vars.PostRandom or true;
CML_Vars.Ask = CML_Vars.Ask or false;
CML_Vars.Quickloot = CML_Vars.Quickloot or "";
CML_Vars.ShowRolls = CML_Vars.ShowRolls or 5;
CML_Vars.RollTimeout = CML_Vars.RollTimeout or 60;
CML_Vars.Rolls = CML_Vars.Rolls or {};
CML_Vars.Roll_Min = CML_Vars.Roll_Min or 1;
CML_Vars.Roll_Max = CML_Vars.Roll_Max or 100;
CML_Vars.BidBodSupport = CML_Vars.BidBodSupport or false;
		-- 创建小地图图标
		XyTracker_CreateMinimapButton()
		-- 初始化按钮位置
		XyButton_UpdatePosition()
		-- 窗口标题版本号跟随 toc 的 ## Version 字段
		if GetAddOnMetadata then
			local ver = GetAddOnMetadata("XyTracker", "Version")
			if ver then
				local _, _, verNum = string.find(ver, "([%d%.]+)")
				XyTrackerFrameTitle:SetText("许愿监视 " .. (verNum or ver))
			end
		end
		return
	end
	
	-- 处理玩家登出事件，确保在退出游戏时保存数据
	if event == "PLAYER_LOGOUT" then
		XyTracker_SaveCustomStarttext()
		-- 登出时保存许愿快照，供崩溃/异常后恢复（XyTracker_Backup.lua）
		XyTracker_SaveWishList()
		return
	end
	
	-- 处理玩家进入世界事件，执行自动清理
	if event == "PLAYER_ENTERING_WORLD" then
		XyTracker_AutoCleanup()
		return
	end
	
	-- ROLL点超时死检查已删除（isRolling/rollEndTime 从未赋值，分支恒不触发）
    if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then

        -- 检查消息是否为0-9的数字，如果是则处理出分拍卖
        local number = tonumber(arg1)
        
        if number and number >= 0 and number <= 9 then
            -- 出分拍卖已移除，仅保留玩家发言记录（自动扣分依赖此记录）
            raidMessages[arg2] = {
                message = number,
                timestamp = GetTime()
            }
        end
          if IsLeader then
          XyTracker_OnSystemMessage()  -- 添加这行来处理系统消息
          end
    end
    -- 检测物品获取
    if event == "CHAT_MSG_LOOT" then
        local player, itemLink = string.match(arg1, "(.+)获得了物品：(.+)。")
        if player and player == "你" then
            player = UnitName("player")
        end
        -- 检查itemLink是否为nil，避免连接错误
        if player and itemLink then
            local msg = player.."获得了物品："..itemLink.."。"
      
        -- 先检查消息是否重复，不重复的才处理
        if not XyTracker_IsDuplicateLoot(msg) then
        
            XyTracker_CHATMSGLOOT(msg)
        end
        end
    end
        -- 新增：团队聊天中检测物品链接并通报（非许愿阶段）
    if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING") then
        CheckItemAndAnnounceWish(arg1, arg2)
    end
    
    --查询许愿
    if event == "CHAT_MSG_WHISPER" then
        if arg1 == "cxxy" then
            XyQuery(arg2)
        end
    end
    -- 团长点开始许愿,所有团员的禁用团长权限,离开队伍后恢复
    -- 若本客户端已是许愿团长，只有真实团长(rank 2)点开始时才让位
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_START" then
        if IsLeader then
            if arg4 ~= UnitName("player") and XyTracker_GetRaidRank(arg4) == 2 then
                IsLeader = false
                DisableLeaderOperation()
                LeaderName = arg4
                XyTracker_UpdateLeaderText()  -- 更新UI显示
                -- 请求LootList同步数据
                SendAddonMessage("XY_LOOTLIST_SYNC_REQUEST", "", "RAID")
            end
        elseif XyTracker_ShouldAcceptLeader(arg4) then
            DisableLeaderOperation()
            LeaderName = arg4 
            XyTracker_UpdateLeaderText()  -- 更新UI显示
            -- 请求LootList同步数据
            SendAddonMessage("XY_LOOTLIST_SYNC_REQUEST", "", "RAID")
        end
    end
    --发送许愿
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_SYNC_NEW" and IsLeader then
        syncXy()
    end
    --同步许愿（只接受当前认定的许愿团长/真实团长的同步，
    --防止XyTracker单人同步自带n=清表头把许愿表反复清空）
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_SYNC" and not IsLeader then
        if XyTracker_ShouldAcceptLeader(arg4) then
            receiveXySync(arg2)
            LeaderName = arg4  
            XyTracker_UpdateLeaderText()  -- 更新UI显示
        end
    end
    -- 同步LootList数据
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_LOOTLIST_SYNC" then
        -- 团长不接收XY_LOOTLIST_SYNC信息
        if not IsLeader then
            receiveLootListSync(arg2)
        end
    end
    -- 接收LootList同步请求
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_LOOTLIST_SYNC_REQUEST" and IsLeader then
        -- 只有团长才响应LootList同步请求
        -- 修改：响应同步请求时也只同步最新物品，不同步所有数据
        if LootList and table.getn(LootList) > 0 then
            -- 获取最新的物品
            local latestItem = LootList[table.getn(LootList)]
            if latestItem then
                -- 构建并发送最新物品的同步消息
                local itemID = ExtractItemID(latestItem.itemLink)
                local points = latestItem.points or 0
                local isWish = latestItem.isWish and 1 or 0
                local safePlayerName = latestItem.playerName or ""
                local hour = 0
            local minute = 0
            if latestItem.timestamp then
                if type(latestItem.timestamp) == "table" and latestItem.timestamp.hour and latestItem.timestamp.minute then
                    hour = latestItem.timestamp.hour
                    minute = latestItem.timestamp.minute
                else
                    -- 对于数字格式时间戳，转换为时分格式
                    local timeStruct = date("*t", latestItem.timestamp)
                    hour = timeStruct.hour or 0
                    minute = timeStruct.min or 0
                end
            end
                
                safePlayerName = string.gsub(safePlayerName, "|", "||")
                local safeItemName = string.gsub(latestItem.itemName or "未知物品", "|", "||")
                
                -- 获取物品品质信息
                local itemQuality = 5 -- 默认紫色史诗
                local itemName, itemLink, quality = GetItemInfo(itemID)
                if quality and type(quality) == "number" then
                    itemQuality = quality
                end
                
                local chunkData = string.format(";i=%s,n=%s,f=%d,x=%d,p=%s,t=%02d:%02d,q=%d",
                    itemID,
                    safeItemName,
                    points,
                    isWish,
                    safePlayerName,
                    hour,
                    minute,
                    itemQuality
                )
                
                local message = string.format("%d:%d:%d%s",
                    table.getn(LootList),
                    table.getn(LootList),  -- 起始索引设为总物品数，确保只发送最新物品
                    table.getn(LootList),  -- 结束索引为总物品数
                    chunkData
                )
                
                SendAddonMessage("XY_LOOTLIST_SYNC", message, "RAID")
            end
        end
    end
    -- 处理放弃权限消息
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_RELINQUISH" then
        -- 恢复初始状态（只重置权限状态，不重置许愿信息）
        IsLeader = false
        LeaderName = ""
        XyInProgress = false
        -- 更新UI显示
        XyTracker_UpdateLeaderText()
        -- 启用所有操作按钮（包括重置和初始化DKP按钮）
        EnableLeaderOperation()
        -- 隐藏放弃权限和停止按钮，显示开始按钮
        getglobal("XyTrackerFrameRelinquishButton"):Hide()
        getglobal("XyTrackerFrameStartButton"):Show()
        getglobal("XyTrackerFrameStopButton"):Hide()
    end
    
    -- 处理队员发送的拾取信息（仅团长接收）
    if event == "CHAT_MSG_ADDON" and arg1 == "XY_MEMBER_LOOT" and IsLeader then
      if not XyTracker_IsDuplicateLoot(arg2) then     
            XyTracker_CHATMSGLOOT(arg2)
        end
    -- 处理团队成员同步的拾取信息
    elseif event == "CHAT_MSG_ADDON" and arg1 == "XY_LOOT_SYNC" then
        -- 所有玩家都接收XY_LOOT_SYNC消息（但团长不处理自己发送的）
        if not IsLeader then
            XyTracker_ReceiveLootSync(arg2, arg4) -- arg4是发送者名称
        end
    end
    --加入团队的时候请求同步数据
    if event == "CHAT_MSG_SYSTEM" and (arg1 == "你加入了一个团队。" or string.find(arg1, "加入了一个团队")) then
        -- 清空上次的许愿团长认定，让新团的团长同步能通过身份校验
        LeaderName = ""
        -- 发送同步请求但保留现有LootList数据
        SendAddonMessage("XY_SYNC_NEW", "", "RAID")
        -- 发送LootList同步请求
        SendAddonMessage("XY_LOOTLIST_SYNC_REQUEST", "", "RAID")
        -- 确保更新拾取列表UI显示
        XyTracker_UpdateLootList()
    end
    
    -- 团队成员变动时的处理（当有新成员加入时）
    if event == "RAID_ROSTER_UPDATE" then
        -- 对于团长：已移除定期广播LootList数据的逻辑，只在拾取时发送一次
        
        -- 对于团员：检查是否有LootList数据，如果没有则请求同步
        if not IsLeader then
            if LootList and table.getn(LootList) == 0 then
                -- 避免频繁请求，只在需要时发送请求
                local currentTime = GetTime()
                if not lastSyncRequestTime or (currentTime - lastSyncRequestTime) > 5 then
                    lastSyncRequestTime = currentTime
                    SendAddonMessage("XY_LOOTLIST_SYNC_REQUEST", "", "RAID")
                end
            end
        end
    end
    --离开队伍后恢复团长功能
    if event == "CHAT_MSG_SYSTEM" and arg1 == "你已经离开了这个团队" then
        IsLeader = false
        LeaderName = ""  -- 同时清空许愿团长认定，避免影响下次进团的同步校验
        -- 先隐藏停止按钮
        getglobal("XyTrackerFrameStopButton"):Hide();
        EnableLeaderOperation()
    end
end




-- 处理系统消息，更新许愿信息
function XyTracker_OnSystemMessage()
    -- 在处理信息之前就根据XY开头直接录入信息
    if not XyInProgress then
        return
    end
    
    if string.lower(string.sub(arg1, 1, 2)) == "xy" then 
        local xytempText = string.gsub(arg1, "^[Xx][Yy]%s*", "")
        -- 直接设置许愿内容，不经过XyTracker_OnXy验证
        local info = getXyInfo(arg2)
        info["xy"] = xytempText
        XyTracker_UpdateList()
        syncXy(arg2) -- 只同步该玩家
        return
    end
    
    local values = {}
    for word in string.gmatch(arg1, "%S+") do
        table.insert(values, word)
    end



    local val1 = values[1]
    
    -- 原有的许愿处理逻辑 - 修改为支持多物品许愿
    if val1 and string.lower(val1) == "xy" and table.getn(values) > 1 then
        -- 检查是否包含多个物品链接
        -- 安全地移除开头的XY命令
        local xyText = ""
        if type(arg1) == "string" then
            local success, result = pcall(function()
                return string.gsub(arg1, "^[Xx][Yy]%s*", "")
            end)
            if success then
                xyText = result
            else
                xyText = arg1
            end
        end
        local hasMultipleItems = string.find(xyText, "|Hitem:.-|h.-|h.*|Hitem:.-|h.-|h")
        
        if hasMultipleItems then
            -- 处理多物品情况
            local itemCount = 0
            for itemLink in string.gmatch(xyText, "|Hitem:.-|h.-|h") do
                itemCount = itemCount + 1
                if itemCount > 1 then -- 跳过第一个物品，避免重复处理
                    XyTracker_OnXy(arg2, itemLink)
                end
            end
        end
        
        -- 处理第一个物品（保持原有逻辑）
        local Xy = values[2]
        XyTracker_OnXy(arg2, Xy)
        XyTracker_UpdateList()
        syncXy(arg2) -- 只同步该玩家
    elseif val1 and string.lower(val1) == "txy" and table.getn(values) > 2 then
        local player = values[2]
        local Xy = values[3]
        XyTracker_OnXy(player, Xy)
        XyTracker_UpdateList()
        syncXy(player) -- 只同步该玩家
    elseif XyTrackerOptions.XyOnlyMode == 0 and arg1 and string.find(arg1, "|Hitem:") then
        -- 检查是否包含多个物品链接
        local hasMultipleItems = string.find(arg1, "|Hitem:.-|h.-|h.*|Hitem:.-|h.-|h")
        
        if hasMultipleItems then
            -- 处理多物品情况
            local itemCount = 0
            for itemLink in string.gmatch(arg1, "|Hitem:.-|h.-|h") do
                itemCount = itemCount + 1
                if itemCount > 1 then -- 跳过第一个物品，避免重复处理
                    XyTracker_OnXy(arg2, itemLink)
                end
            end
        end
        
        -- 处理第一个物品（保持原有逻辑）
        local Xy = arg1
        XyTracker_OnXy(arg2, Xy)
        XyTracker_UpdateList()
        syncXy(arg2) -- 只同步该玩家
    end
end

function receiveXySync(msg)
    DisableLeaderOperation()
    -- 标记开始接收同步数据
    IsReceivingSync = true
    --获取同步开始
    for n, x in string.gfind(msg, "n=(.+),x=(.+)") do
        Xys = x
        XyArray = {}
        XyTracker_UpdateList()
        
        -- 【重要】设置数据变更标记，确保在游戏退出时自动保存
        _G["XyTracker_SavedWishList_LastUpdate"] = time()
        -- 记录当前XyArray的实际大小，用于验证
        _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
        return
    end
    for p, c, x, s in string.gfind(msg, "p=(.+),c=(.+),x=(.+),s=(.+)") do
        -- 检查玩家是否已存在
        local playerExists = false
        local n = table.getn(XyArray)
        local oldXy = ""
        
        for i = 1, n do
            if XyArray[i]["name"] == p then
                playerExists = true
                oldXy = XyArray[i]["xy"] or ""
                -- 更新现有玩家的数据（未许愿保持"---未许愿---"，不要存空串：
                -- 空串再次转发时会拼出 x=,s= 的非法行，所有版本的解析正则都会把整条丢弃）
                XyArray[i]["class"] = c
                XyArray[i]["xy"] = x
                XyArray[i]["dkp"] = s
                XyArray[i]["timestamp"] = time() -- 更新时间戳
                break
            end
        end
        
        -- 如果玩家不存在，则添加新记录
        if not playerExists then
            local info = {}
            info["name"] = p
            info["class"] = c
            info["xy"] = x
            info["dkp"] = s
            info["timestamp"] = time() -- 添加时间戳
            table.insert(XyArray, info)
        end
        
        -- 检查是否发生了许愿变更（从无到有或内容改变）
        -- 重要修复：在接收同步数据时不发送公告，避免重复公告
        if XyTrackerOptions.AutoAnnounce and x ~= "---未许愿---" and x ~= "" and x ~= oldXy and not IsReceivingSync then
            -- 触发重复许愿检查（与自动查询对齐：只统计当前在团成员，离队灰色成员不计入）
            local itemName = ExtractItemName(x)
            local count = 0
            local raidMembers = XYT_BuildRaidMemberSet()
            for i = 1, table.getn(XyArray) do
                local currentXY = ExtractItemName(XyArray[i]["xy"] or "")
                if currentXY == itemName and raidMembers[XyArray[i]["name"]] then
                    count = count + 1
                end
            end
            
            if count >= 2 then
                -- 使用全局的安全字符串清理函数
                local cleanItemName = safeCleanString(itemName)
                
                -- 重要修复：确保cleanItemName不为空
                if cleanItemName == "" and itemName ~= "" then
                    cleanItemName = itemName -- 回退到原始名称
                end
                
                -- 只有当cleanItemName确实有内容时才发送公告
                if cleanItemName ~= "" then
                    local currentLanguage = GetDefaultLanguage("player")
                    SendChatMessage("☆"..cleanItemName.."☆已有 "..count.." 人许愿！", "RAID", currentLanguage, nil)
                end
            end
        end
        
        -- 【重要】设置数据变更标记，确保在游戏退出时自动保存
        _G["XyTracker_SavedWishList_LastUpdate"] = time()
        -- 记录当前XyArray的实际大小，用于验证
        _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
    end

    -- 性能：整个同步循环结束后统一刷新一次UI，不再每条消息都全量刷新
    XyTracker_UpdateList()

    -- 同步结束，重置标记
    IsReceivingSync = false
end

function syncXy(playerName)
    local n = table.getn(XyArray)
    local msg = "";
    
    -- 添加移除颜色标记的函数
    local function removeColorMarkup(text)
        if type(text) == "string" then
            -- 移除形如 |cFF00FF00 的颜色代码和 |r 重置代码
            text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            text = string.gsub(text, "|r", "")
        end
        return text
    end
    
    -- 如果提供了playerName参数，只同步特定玩家的数据
    if playerName then
        -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker调试] 同步特定玩家: " .. playerName)
        local cleanPlayerName = removeColorMarkup(playerName)
        for i = 1, n do
            local info = XyArray[i]
            if info["name"] and removeColorMarkup(info["name"]) == cleanPlayerName then
                local player = info["name"]
                local xy = info["xy"]
                if not xy or xy == "" then xy = "---未许愿---" end  -- 空串会让接收端正则匹配失败、整条丢弃
                local dkp = info["dkp"] or 4
                local class = info["class"] or "无"
                
                -- 注意：单人同步不发送 n= 消息，接收端收到 n= 会清空整个许愿表
                -- 只发送该玩家的数据
                msg = "p=" .. player .. ",c=" .. class .. ",x=" .. xy .. ",s=" .. dkp
                SendAddonMessage("XY_SYNC", msg, "RAID")
                break
            end
        end
    else
        -- 没有提供playerName参数时，同步所有数据
        -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker调试] 同步所有玩家许愿数据")
        if n > 0 then
            msg = "n=" .. n .. ",x=" .. Xys
            SendAddonMessage("XY_SYNC", msg, "RAID")
            for i = 1, n do
                local info = XyArray[i]
                local player = info["name"]
                local xy = info["xy"]
                if not xy or xy == "" then xy = "---未许愿---" end  -- 空串会让接收端正则匹配失败、整条丢弃
                local dkp = info["dkp"] or 4
                local class = info["class"] or "无"
                msg = "p=" .. player .. ",c=" .. class .. ",x=" .. xy .. ",s=" .. dkp
                SendAddonMessage("XY_SYNC", msg, "RAID")
            end
        end
    end
end

function DisableLeaderOperation()
    --这个必须保留，避免团员在进团之前开过许愿 by 无道暴君 20250217
    XyInProgress = false
    getglobal("XyTrackerFrameStartButton"):Hide();
    getglobal("XyTrackerFrameStopButton"):Hide();
    getglobal("XyTrackerFrameResetButton"):Hide();
    -- 隐藏编辑文本按钮（队员模式）
    if getglobal("XyTrackerFrameEditStarttextButton") then
        getglobal("XyTrackerFrameEditStarttextButton"):Hide();
    end
    -- 未许愿人数按钮在团员模式下也显示
    --getglobal("XyTrackerFrameAnnounceButton"):Hide();
    -- 导出许愿按钮在团员模式下也显示
    --getglobal("XyTrackerFrameExportButton"):Hide();
    getglobal("XyTrackerFrameChuShiHua_DKP"):Hide();
    -- 团员端隐藏宣言相关按钮
    getglobal("XyTrackerFrameDeclarationButton"):Hide();
    getglobal("XyTrackerFrameAnnounceDeclarationButton"):Hide();
    getglobal("XyTrackerDeclarationLargeEditBox"):Hide();
end

function EnableLeaderOperation()
    XyInProgress = false
    getglobal("XyTrackerFrameStartButton"):Show();
    getglobal("XyTrackerFrameResetButton"):Show();
    -- 显示编辑文本按钮（团长模式）
    if getglobal("XyTrackerFrameEditStarttextButton") then
        getglobal("XyTrackerFrameEditStarttextButton"):Show();
    end
    getglobal("XyTrackerFrameAnnounceButton"):Show();
    getglobal("XyTrackerFrameExportButton"):Show();
    getglobal("XyTrackerFrameChuShiHua_DKP"):Show();
    -- 团长端显示宣言按钮
    getglobal("XyTrackerFrameDeclarationButton"):Show();
    getglobal("XyTrackerFrameAnnounceDeclarationButton"):Show();
end

function XyQuery(player, dkpnumber)

    local n = table.getn(XyArray)
    for i = 1, n do
        local name = XyArray[i]["name"]
        local xy = XyArray[i]["xy"]
        local currentDKP = XyArray[i]["dkp"] -- 直接使用存储的值，不做任何转换或限制
        
        if not xy then
            xy = ""
        end
        if player == name then
                if dkpnumber and dkpnumber ~= 0 then
                    dkpnumber = tonumber(dkpnumber) or 0;  -- 确保dkpnumber是数字类型
                    if dkpnumber > 0 then
                        SendChatMessage(player .. " 增加[" .. dkpnumber .. "]分,当前剩余分数：[" .. currentDKP .. "]", "RAID", this.language, nil);
                    else
                        SendChatMessage(player .. " 扣除[" .. 0 - dkpnumber .. "]分,当前剩余分数：[" .. currentDKP .. "]", "RAID", this.language, nil);
                    end
                else
                    SendChatMessage(player .. " 许愿[" .. xy .. "],当前剩余分数：[" .. currentDKP .. "]", "RAID", this.language, nil);
                end
                break -- 找到玩家后就退出循环
            end
    end
end


function XyTracker_OnXy(name, Xy)
    if not XyInProgress then
        return
    end
    
    local info = getXyInfo(name)
    
    -- 验证许愿内容：只允许纯物品链接
    local validatedWish = ""
    
    if Xy and Xy ~= "" then
        -- 首先检查是否只包含纯物品链接（允许连续或空格分隔）
        local tempText = string.gsub(Xy, "%s+", " ")  -- 标准化空白字符
        
        -- 检查是否只包含标准物品链接和简化物品链接
        local isValid = true
        
        -- 验证逻辑：只检查物品链接格式
            -- 创建一个临时字符串，移除所有有效的物品链接
            local temp = tempText
            
            -- 移除所有标准物品链接格式
            temp = string.gsub(temp, "|c%x%x%x%x%x%x%x%x|Hitem:[^|]+|h[^|]+|h|r", "")
            
            -- 移除所有简化物品链接格式
            temp = string.gsub(temp, "%[[^%]]+%]", "")
            
            -- 移除所有剩余的空白字符
            temp = string.gsub(temp, "%s+", "")
            
            -- 如果还有剩余内容，说明包含非法字符
            if temp ~= "" then
                isValid = false
            end
        
        
        -- 额外检查：确保至少有一个有效的物品链接
            local hasLink = false
            -- 检查是否有标准链接
            if string.find(tempText, "|c%x%x%x%x%x%x%x%x|Hitem:") then
                hasLink = true
            end
            -- 检查是否有简化链接
            if not hasLink and string.find(tempText, "%[[^%]]+%]") then
                hasLink = true
            end
            -- 如果没有任何链接，仍然视为无效
            if not hasLink then
                isValid = false
            end
        
        
        if isValid then
            -- 提取有效的物品链接
                -- 只包含物品链接，提取所有有效的物品链接
                local parts = {}
                local foundLinks = {} -- 用于去重的表
            
            -- 首先提取标准物品链接格式（优先级高）
            for link in string.gmatch(Xy, "(|c%x%x%x%x%x%x%x%x|Hitem:[^|]+|h[^|]+|h|r)") do
                -- 提取物品名称作为去重键
                local itemName = string.match(link, "|h%[(.-)%]|h|r$")
                if itemName and not foundLinks[itemName] then
                    foundLinks[itemName] = true
                    table.insert(parts, link)
                end
            end
            
            -- 然后提取简化物品链接格式（如[魔导书：恶魔之门]），避免重复
            for link in string.gmatch(Xy, "(%[[^%]]+%])") do
                -- 检查是否是有效的物品名称格式（不能为空）
                if string.match(link, "^%[[^%]]+%]$") and not string.match(link, "^%[%s*%]$") then
                    -- 提取物品名称作为去重键
                    local itemName = string.match(link, "^%[(.-)%]$" )
                    if itemName and not foundLinks[itemName] then
                        foundLinks[itemName] = true
                        table.insert(parts, link)
                    end
                end
            end
            
            -- 如果有找到物品链接，用空格分隔
            if table.getn(parts) > 0 then
                validatedWish = table.concat(parts, " ")
            else
                -- 如果没有找到任何物品链接，保持原来的许愿内容不变
                validatedWish = info["xy"] or ""  -- 保留原有内容
            end
        else
            -- 不符合要求的内容，保持原有许愿内容不变，不做任何操作
            validatedWish = info["xy"] or ""  -- 保留原有内容
            -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 许愿内容只能包含纯物品链接，请重新输入")
        end
    end
    
    info["xy"] = validatedWish
    
    -- 只有团长端会弹出界面
    if IsLeader then
    XyTracker_ShowXyWindow()
    end
    
    -- 重复许愿检查（只统计当前在团成员，离队灰色成员不计入）。
    -- 注意：本函数入口有 XyInProgress 门槛，点停止许愿后新消息不再录入、此警报也不会再触发；
    -- 停止后仍可用的播报是自动查询（CheckItemAndAnnounceWish 无 XyInProgress 限制）
    local itemName = ExtractItemName(Xy)
    local count = 0
    local currentLanguage = this.language or GetDefaultLanguage("player") -- 确保有有效的语言设置
    local raidMembers = XYT_BuildRaidMemberSet()
    for i = 1, table.getn(XyArray) do
        local currentXY = ExtractItemName(XyArray[i]["xy"] or "")
        if currentXY == itemName and raidMembers[XyArray[i]["name"]] then
            count = count + 1
        end
    end
    if XyTrackerOptions.AutoAnnounce and count >= 2 then
        -- 确保在多物品许愿场景下，每个物品的重复检查都能独立进行
        -- 使用全局的安全字符串清理函数
        local cleanItemName = safeCleanString(itemName)
        SendChatMessage("☆"..cleanItemName.."☆已有 "..count.." 人许愿！", "RAID", currentLanguage, nil)
    end
    
    -- 【重要】设置数据变更标记，确保在游戏退出时自动保存
    _G["XyTracker_SavedWishList_LastUpdate"] = time()
    -- 记录当前XyArray的实际大小，用于验证
    _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
end

function XyTracker_OnStartButtonClick()
    -- 检查是否在团队中（已移除5人小队许愿支持）
    if GetNumRaidMembers() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[XyTracker] 你不在一个团队中，无法开始|r")
        return
    end
    
    if GetNumRaidMembers() > 1 then
        IsLeader = true
        LeaderName = UnitName("player")  -- 记录当前玩家作为许愿权限拥有者
        XyTracker_UpdateLeaderText()  -- 更新UI显示

        local Starttext = XyTracker_GetCurrentStarttext()
	SendChatMessage(Starttext, "RAID", this.language, nil);
        XyInProgress = true
        
        -- 重新注册右键菜单按钮，确保团长权限按钮可见
        XyTracker_RegisterRightClickMenuButtons()
        
        -- 注释掉播报所有人许愿的代码
        -- XyTracker_AnnounceAllWishes()
        
        XyTracker_ShowXyWindow()
    -- 显示放弃权限按钮，隐藏开始按钮
    getglobal("XyTrackerFrameRelinquishButton"):Show()
    getglobal("XyTrackerFrameStartButton"):Hide()
    getglobal("XyTrackerFrameStopButton"):Show()
        --同步到团员端
        SendAddonMessage("XY_START", "", "RAID")
        -- 立即同步当前的LootList数据给所有团员
        XyTracker_UpdateList()
        
    end
end

-- 更新许愿权限拥有者显示文本
function XyTracker_UpdateLeaderText()
 
    local leaderText = getglobal("XyTrackerLeaderText")
    if leaderText then
        -- 确保文本元素可见
        leaderText:Show()
    
        -- 设置正确的显示文本
        if LeaderName and LeaderName ~= "" then
            leaderText:SetText("许愿权：" .. LeaderName)
        else
            leaderText:SetText("许愿权：无人")
        end
        
        -- 添加调试信息，帮助排查问题
        -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 更新许愿权限拥有者显示: " .. (LeaderName or "无人"))
    else
        -- 尝试动态创建元素，确保显示
        if XyTrackerFrame and XyTrackerFrameStatusText then
            leaderText = XyTrackerFrame:CreateFontString("XyTrackerLeaderText", "ARTWORK", "GameFontNormalSmall")
            leaderText:SetPoint("LEFT", XyTrackerFrameStatusText, "LEFT", 88, 0)
            leaderText:SetWidth(180)
            leaderText:SetHeight(16)
            leaderText:SetTextColor(1.0, 0.82, 0)
            leaderText:SetJustifyH("LEFT")
            leaderText:SetJustifyV("MIDDLE")
            leaderText:Show()
            
            -- 设置文本内容
            if LeaderName and LeaderName ~= "" then
                leaderText:SetText("许愿权：" .. LeaderName)
            else
                leaderText:SetText("许愿权：无人")
            end
        end
    end
end

function XyTracker_OnStopButtonClick()
    SendChatMessage("许愿结束，后续许愿无效", "RAID", this.language, nil)
    XyInProgress = false
    
end

function XyTracker_OnRelinquishButtonClick()
    -- 检查当前用户是否拥有许愿权
    local playerName = UnitName("player")
    if IsLeader and LeaderName == playerName then
        -- 弹出确认对话框
        StaticPopupDialogs["XYTRACKER_CONFIRM_RELINQUISH"] = {
            text = "确定要放弃许愿团团长的权限吗？",
            button1 = "确定",
            button2 = "取消",
            OnAccept = function()
                -- 放弃许愿权
                IsLeader = false
                LeaderName = ""
                
                -- 发送插件信息给其他用户
                SendAddonMessage("XY_RELINQUISH", "", "RAID")
                
                -- 发送聊天消息
                SendChatMessage("已放弃许愿团团长权限，请要权限的点击开始拿回权限", "RAID", this.language, nil)
                
                -- 更新UI显示
                XyTracker_UpdateLeaderText()
                
                -- 启用所有操作按钮（包括重置和初始化DKP按钮）
                EnableLeaderOperation()
                
                -- 隐藏放弃权限按钮，显示开始按钮
                getglobal("XyTrackerFrameRelinquishButton"):Hide()
                getglobal("XyTrackerFrameStartButton"):Show()
                getglobal("XyTrackerFrameStopButton"):Hide()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("XYTRACKER_CONFIRM_RELINQUISH")
    end
end

-- tempDeductedPoints 已在文件头部统一声明（此处原 local 声明在使用点之后，为死声明，已移除）

function XyTracker_OnClearButtonClick()
    -- 弹出确认对话框
    StaticPopup_Show("XYTRACKER_CONFIRM_RESET")
    
end

-- 注册静态弹窗
StaticPopupDialogs["XYTRACKER_CONFIRM_RESET"] = {
    text = "确定要重置所有成员的许愿数据吗？",
    button1 = "确定",
    button2 = "取消",
    OnAccept = function()
        XyTracker_DoActualClear()  -- 实际执行重置
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true
}

-- 自动清理超过24小时的许愿信息和拾取列表数据
function XyTracker_AutoCleanup()
    local now = time()
    local oneDay = 86400 -- 24小时秒数
    
    -- 清理XyArray中超过24小时的许愿信息
    if XyArray and type(XyArray) == "table" then
        local newXyArray = {}
        for i = 1, table.getn(XyArray) do
            local entry = XyArray[i]
            if entry then
                -- 保留没有timestamp（旧数据）或timestamp小于24小时的条目
                if not entry.timestamp or (now - entry.timestamp) < oneDay then
                    table.insert(newXyArray, entry)
                end
            end
        end
        XyArray = newXyArray
    end
    
    -- 清理LootList中超过24小时的拾取列表数据
    if LootList and type(LootList) == "table" then
        local newLootList = {}
        for i = 1, table.getn(LootList) do
            local entry = LootList[i]
            if entry then
                local entryTimestamp = entry.timestamp
                -- 表格式时间戳为旧格式遗留数据，无法确定具体日期，按过期处理直接清理（不再豁免）
                if type(entryTimestamp) == "table" then
                    entryTimestamp = 0
                end
                if not entryTimestamp or type(entryTimestamp) ~= "number" or (now - entryTimestamp) < oneDay then
                    table.insert(newLootList, entry)
                end
            end
        end
        LootList = newLootList
    end
    
    XyTracker_UpdateList()
end

function XyTracker_DoActualClear()
    XyArray = {}  -- 清空所有玩家信息，包括已退组的
    XyItemCount = {}  -- 新增：清空物品计数
    NoXyList = ""  -- 清空未许愿列表
    -- 重置时一并清空拾取列表（与"清除列表"按钮一致）
    LootList = {}
    _G["OriginalFilteredLootList"] = {}
    _G["FilteredLootList"] = {}
    XyTracker_UpdateLootList()
    
    -- 不重新添加任何玩家，保持数组完全清空
    XyTracker_UpdateList()
    if IsLeader then
        syncXy()
    end
end

function XyTracker_OnRefreshButtonClick()
    local totalMembers = GetNumRaidMembers()
    if totalMembers and totalMembers > 0 then
        -- 创建一个临时表来存储现有的许愿信息，使用玩家名字作为索引
        local existingWishes = {}
        for i = 1, table.getn(XyArray) do
            local info = XyArray[i]
            existingWishes[info["name"]] = {
                index = i,
                xy = info["xy"],
                dkp = info["dkp"] or DefaultDKP,
                class = info["class"]
            }
        end
        
        -- 检查当前团队中的所有成员，确保他们在XyArray中有记录
        for i = 1, totalMembers do
            local name, rank, subgroup, level, class = GetRaidRosterInfo(i)
            
            -- 如果该玩家之前有许愿信息，则更新职业（可能有变化）
            if existingWishes[name] then
                XyArray[existingWishes[name].index]["class"] = class
            else
                -- 如果是新成员，添加到XyArray
                local info = {}
                info["name"] = name
                info["class"] = class
                info["dkp"] = 4
                info["xy"] = "---未许愿---"
                info["timestamp"] = time() -- 添加时间戳
                table.insert(XyArray, info)
            end
        end
        
        if IsLeader then
            -- 队长直接发布同步信息
            syncXy()
        else
            -- 队员请求队长发送同步信息（包括许愿和拾取数据）
            SendAddonMessage("XY_SYNC_NEW", "", "RAID")
            SendAddonMessage("XY_LOOTLIST_SYNC_REQUEST", "", "RAID")
        end
    end
    XyTracker_UpdateList()
end

-- 显示拾取列表窗口
function XyTracker_ShowLootListFrame()
    local lootFrame = getglobal("XyTrackerLootListFrame")
    if lootFrame then
        lootFrame:Show()
        XyTracker_UpdateLootList()
    end
end

-- 更新拾取列表
function XyTracker_UpdateLootList()
    -- 确保LootList存在
    if not LootList then
        LootList = {}
    end
    
    -- 对拾取列表进行排序
    XyLootSortList()
    
    local scrollFrame = getglobal("LootListScrollFrame")
    local numItems = table.getn(LootList)
    
    FauxScrollFrame_Update(scrollFrame, numItems, 16, 25)
    
    for i = 1, 16 do
        local button = getglobal("LootFrameListButton"..i)
        local index = i + FauxScrollFrame_GetOffset(scrollFrame)
        
        if index <= numItems then
            local lootItem = LootList[index]
            
            -- 加强数据验证，确保lootItem是有效表
            if not lootItem or type(lootItem) ~= "table" then
                button:Hide()
                -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 跳过无效的拾取列表项 (索引: " .. index .. ")")
            else
                -- 设置按钮可见
                button:Show()
                
                -- 设置物品名称并根据品质染色
                local nameText = getglobal(button:GetName().."Name")
                if nameText then
                    local safeItemName = lootItem.itemName and tostring(lootItem.itemName) or "未知物品"
                    local safeItemLink = lootItem.itemLink and tostring(lootItem.itemLink) or ""
                    
                    -- 安全地从物品链接中提取颜色代码
                    local itemColor = nil
                    if safeItemLink and safeItemLink ~= "" then
                        local success, _, _, color = pcall(string.find, safeItemLink, "|c(%x+)|H")
                        if success and color then
                            itemColor = color
                        end
                    end
                    
                    -- 应用颜色或使用默认颜色
                    if itemColor then
                        -- 确保颜色代码格式正确
                        if string.len(itemColor) == 8 then
                            nameText:SetText("|c"..itemColor..safeItemName.."|r")
                        else
                            nameText:SetText(safeItemName)
                        end
                    else
                        nameText:SetText(safeItemName)
                    end
                    nameText:SetWidth(100)  -- 缩短物品名称宽度
                end
                
                -- 设置拾取时间
                local timeText = getglobal(button:GetName().."Time")
                if timeText then
                    local safeTimestamp = lootItem.timestamp -- 传递所有类型的timestamp，Xy_FormatTime会处理
                    local timeString = Xy_FormatTime(safeTimestamp)
                    timeText:SetText(timeString)
                    timeText:SetWidth(80)
                end
                
                -- 设置归属玩家
                local playerText = getglobal(button:GetName().."Xy")
                if playerText then
                    local safePlayerName = lootItem.playerName and tostring(lootItem.playerName) or "未知玩家"
                    -- 获取玩家职业并添加职业染色
                    local playerInfo = getXyInfo(safePlayerName)
                    local class = playerInfo and playerInfo["class"] or "未知"
                    local classColor = XYT_GetClassColor(class) or "|cffffffff"
                    local coloredPlayerName = classColor .. safePlayerName .. "|r"
                    playerText:SetText(coloredPlayerName)
                    playerText:SetWidth(80)
                end
                
                -- 设置使用分数
                local pointsText = getglobal(button:GetName().."DKP")
                if pointsText then
                    local safePoints = type(lootItem.points) == "number" and lootItem.points or 0
                    pointsText:SetText(safePoints)
                    pointsText:SetWidth(50)
                end
                
                -- 隐藏拾取列表中的加减分和许愿完成按钮
                local addButton = getglobal(button:GetName().."AddDkp")
                local minusButton = getglobal(button:GetName().."MinusDkp")
                local completeButton = getglobal(button:GetName().."CompleteWish")
                if addButton then
                    addButton:Hide()
                end
                if minusButton then
                    minusButton:Hide()
                end
                if completeButton then
                    completeButton:Hide()
                end
                
                -- 设置是否许愿
                local isWishText = getglobal(button:GetName().."IsWish")
                if isWishText then
                    local safeIsWish = type(lootItem.isWish) == "boolean" and lootItem.isWish or false
                    if safeIsWish then
                        -- 许愿成功，显示不同颜色和文字
                        isWishText:SetText("已许愿")
                        isWishText:SetTextColor(1, 0.5, 0, 1)  -- 橙色，代表许愿成功
                    else
                        isWishText:SetText("否")
                        isWishText:SetTextColor(1, 1, 1, 1)  -- 白色
                    end
                    isWishText:SetWidth(60)
                end
            end
            
            -- 设置背景颜色
            if math.mod(index, 2) == 0 then
                button:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
            else
                button:SetBackdropColor(0, 0, 0, 0.5)
            end
            
            -- 禁用鼠标滑过操作
            button:SetScript("OnEnter", nil)
            button:SetScript("OnLeave", nil)
        else
            button:Hide()
        end
    end
end

-- 格式化时间戳或获取当前游戏时间
function Xy_FormatTime(timestamp)
    if timestamp then
        -- 有时间戳时使用时间戳
        if type(timestamp) == "table" and timestamp.hour and timestamp.minute then
            -- 处理新的{hour, minute}格式的时间戳
            return string.format("%02d:%02d", timestamp.hour, timestamp.minute)
        elseif type(timestamp) == "number" then
            -- 处理数字格式的时间戳（Unix时间戳）
            local timeStruct = date("*t", timestamp)
            return string.format("%02d:%02d", timeStruct.hour or 0, timeStruct.min or 0)
        else
            -- 兼容旧的时间戳格式
            -- 使用本地时间而非服务器时间
            local hour, min = tonumber(date("%H")), tonumber(date("%M"))
            return string.format("%02d:%02d", hour, min)
        end
    else
        -- 无时间戳时使用游戏时间
        -- 使用本地时间而非服务器时间
        local hour, min = tonumber(date("%H")), tonumber(date("%M"))
        return string.format("%02d:%02d", hour, min)
    end
end

-- 从物品链接中提取物品品质的辅助函数
function GetItemQualityFromLink(itemLink)
    if not itemLink or type(itemLink) ~= "string" then
        return 0
    end
    
    -- 尝试从物品链接中提取品质信息
    -- 物品链接格式: |cffa335ee|Hitem:12345:0:0:0:0:0:0:0|h[物品名称]|h|r
    local qualityCode = string.match(itemLink, "|c(%x+)|Hitem")
    if not qualityCode then
        return 0
    end
    
    -- 根据颜色代码映射到品质等级
    local qualityMap = {
        ["ff9d9d9d"] = 0, -- 灰色/垃圾
        ["ffffffff"] = 1, -- 白色/普通
        ["ff1eff00"] = 2, -- 绿色/优秀
        ["ff0070dd"] = 3, -- 蓝色/精良
        ["ffa335ee"] = 4, -- 紫色/史诗
        ["ffff8000"] = 5, -- 橙色/传说
        ["ffe6cc80"] = 6  -- 金色/神器
    }
    
    return qualityMap[string.lower(qualityCode)] or 0
end

-- 对拾取列表进行排序
function XyLootSortList()
    -- 确保LootList是一个有效的表
    if not LootList or type(LootList) ~= "table" or table.getn(LootList) <= 1 then
        return
    end

    -- 性能：装饰排序——先O(n)预计算每条的排序键，比较器只读预计算值，避免比较时反复做字符串操作
    -- 时间值转换函数（从比较器中提出来，整个排序只定义一次）
    local function getTimeValue(timeVal)
        if not timeVal then
            return 0
        end

        -- 检查是否是数字类型（Unix时间戳）
        if type(timeVal) == "number" then
            return timeVal
        end

        -- 检查是否是表类型并包含hour和minute
        if type(timeVal) == "table" and timeVal.hour and timeVal.minute then
            -- 将时间转换为总分钟数进行比较
            return timeVal.hour * 60 + timeVal.minute

        -- 检查是否是字符串格式的时间（时:分）
        elseif type(timeVal) == "string" then
            local hours, minutes = string.match(timeVal, "(%d+):(%d+)")
            if hours and minutes then
                return tonumber(hours) * 60 + tonumber(minutes)
            end
        end

        return 0 -- 默认值
    end

    -- 预计算每条的排序键
    local sortKeys = {}
    for i = 1, table.getn(LootList) do
        local item = LootList[i]
        if item ~= nil then
            local key = {}
            if type(item) == "table" then
                key.val = item[LootSortField]
                key.itemName = item.itemName or ""
                if LootSortField == "itemName" then
                    key.quality = GetItemQualityFromLink(item.itemLink or "")
                    key.itemID = tonumber(ExtractItemID(item.itemLink or "")) or 0
                elseif LootSortField == "timestamp" then
                    key.timeVal = getTimeValue(item.timestamp)
                elseif LootSortField == "isWish" then
                    key.wishFlag = item.isWish and 1 or 0
                end
            end
            sortKeys[item] = key
        end
    end

    table.sort(LootList, function(a, b)
        -- 确保a和b是有效的表
        if not a or type(a) ~= "table" then
            return false
        end
        if not b or type(b) ~= "table" then
            return true
        end

        -- 读取预计算的排序键
        local ka = sortKeys[a]
        local kb = sortKeys[b]

        -- 特殊处理物品名称排序：先按品质，再按ID
        if LootSortField == "itemName" then
            -- 先按品质排序（高品质在前）
            if ka.quality ~= kb.quality then
                return ka.quality * LootSortOrder > kb.quality * LootSortOrder
            else
                -- 品质相同时，按物品ID排序
                return ka.itemID * LootSortOrder < kb.itemID * LootSortOrder
            end

        -- 如果两个值相等，按物品名称排序
        elseif ka.val == kb.val then
            return ka.itemName < kb.itemName
        else
            if LootSortField == "timestamp" then
                return ka.timeVal * LootSortOrder < kb.timeVal * LootSortOrder
            elseif LootSortField == "isWish" then
                -- 特殊处理是否许愿字段，已许愿的应该排在前面
                return ka.wishFlag * LootSortOrder > kb.wishFlag * LootSortOrder -- 注意这里是大于号，让已许愿的排在前面
            elseif type(ka.val) == "number" and type(kb.val) == "number" then
                return ka.val * LootSortOrder < kb.val * LootSortOrder
            else
                -- 对于字符串和其他类型，转换为字符串后比较
                return tostring(ka.val or "") < tostring(kb.val or "")
            end
        end
    end)
end

-- 设置排序字段
function XyLootSortOptions(field)
    -- 确保排序变量已初始化
    if not LootSortField then
        LootSortField = "timestamp"
    end
    if not LootSortOrder then
        LootSortOrder = 1
    end
    
    -- 更新排序字段和顺序
    if LootSortField == field then
        LootSortOrder = -LootSortOrder
    else
        LootSortField = field
        LootSortOrder = 1
    end
    
    -- 只对筛选后的列表进行排序，不再重新排序原始列表和重新应用筛选
    -- 确保即使在多次点击表头时，也只使用筛选后的列表，不会混入被筛选掉的物品
    
    -- 确保FilteredLootList和OriginalFilteredLootList存在
    if not _G["FilteredLootList"] or type(_G["FilteredLootList"]) ~= "table" then
        _G["FilteredLootList"] = {}
    end
    if not _G["OriginalFilteredLootList"] or type(_G["OriginalFilteredLootList"]) ~= "table" then
        _G["OriginalFilteredLootList"] = {}
    end
    
    -- 重新从OriginalFilteredLootList创建FilteredLootList，确保使用的是经过筛选的数据
    _G["FilteredLootList"] = {}
    for i = 1, table.getn(_G["OriginalFilteredLootList"]) do
        _G["FilteredLootList"][i] = _G["OriginalFilteredLootList"][i]
    end
    
    -- 强制刷新UI，XyTracker_UpdateLootList会使用FilteredLootList
    XyTracker_UpdateLootList()
    
    -- 重置滚动条位置，但只使用FilteredLootList
    local scrollFrame = getglobal("LootListScrollFrame")
    if scrollFrame then
        FauxScrollFrame_SetOffset(scrollFrame, 0)
        local filteredCount = table.getn(_G["FilteredLootList"] or {})
        FauxScrollFrame_Update(scrollFrame, filteredCount, 16, 25)
    end
    
    -- 强制重新布局，但只使用FilteredLootList
    local lootFrame = getglobal("XyTrackerLootListFrame")
    if lootFrame and lootFrame:IsVisible() then
        -- 先完全隐藏并重新显示框架，确保所有状态被重置
        lootFrame:Hide()
        
        -- 强制清空所有按钮，确保没有旧数据残留
        for i=1, 16 do
            local button = getglobal("LootFrameListButton"..i)
            if button then
                button:Hide()
            end
        end
        
        lootFrame:Show()
    end
    
    -- 再次调用XyTracker_UpdateLootList确保最新的筛选数据被正确显示
    XyTracker_UpdateLootList()
end

-- 清除拾取列表
function XyTracker_ClearLootList()
    -- 清空所有列表数据，包括原始列表和筛选后的临时表
    LootList = {}
    _G["OriginalFilteredLootList"] = {}
    _G["FilteredLootList"] = {}
    XyTracker_UpdateLootList()
end

-- 从物品链接中提取物品ID的辅助函数
function ExtractItemID(itemLink)
    if not itemLink or type(itemLink) ~= "string" then
        return "0"  -- 返回默认值而不是空字符串
    end
    
    -- 尝试从物品链接中提取物品ID
    local itemID = string.match(itemLink, "|Hitem:(%d+)")
    return itemID or "0"  -- 确保总是返回一个有效的字符串
end

-- 团长同步LootList数据给所有团员
-- 参数: onlyNewItem - 是否只同步最新拾取的物品（默认：false，同步全部）
-- 参数: specificItem - 可选，指定要同步的具体物品对象
function syncLootList(onlyNewItem, specificItem)
    onlyNewItem = onlyNewItem or false
    
    -- 检查LootList是否存在且有数据
    if not LootList or table.getn(LootList) == 0 then
        return
    end
    
    -- 分段发送LootList数据
    -- 由于AddonMessage有长度限制，我们需要确保每件物品单独发送
    local currentIndex = 1
    local chunkSize = 1  -- 每次只发送1个物品
    local totalItems = table.getn(LootList)
    
    -- 如果只同步最新物品
    if onlyNewItem then
        currentIndex = totalItems  -- 从最后一个物品开始
        chunkSize = 1  -- 每次只发送1个物品
        -- 只处理最新的一个物品，不进行批量处理
        local lootItem = specificItem or LootList[currentIndex]
        if lootItem then
            -- 从物品链接中提取物品ID，只发送关键信息
            local itemID = ExtractItemID(lootItem.itemLink)
            local points = lootItem.points or 0
            local isWish = lootItem.isWish and 1 or 0
            local safePlayerName = lootItem.playerName or ""
            local hour = 0
            local minute = 0
            if lootItem.timestamp then
                if type(lootItem.timestamp) == "table" and lootItem.timestamp.hour and lootItem.timestamp.minute then
                    hour = lootItem.timestamp.hour
                    minute = lootItem.timestamp.minute
                else
                    -- 对于数字格式时间戳，转换为时分格式
                    local timeStruct = date("*t", lootItem.timestamp)
                    hour = timeStruct.hour or 0
                    minute = timeStruct.min or 0
                end
            end
            
            -- 替换可能导致解析问题的特殊字符
            safePlayerName = string.gsub(safePlayerName, "|", "||")  -- 转义竖线
            local safeItemName = lootItem.itemName or "未知物品"
            safeItemName = string.gsub(safeItemName, "|", "||")  -- 转义物品名称中的竖线
            
            -- 确保itemID不为空
            if not itemID or itemID == "" then
                itemID = "0"
            end
            
            -- 获取物品品质信息
            local itemQuality = 5 -- 默认紫色史诗
            local itemName, itemLink, quality = GetItemInfo(itemID)
            if quality and type(quality) == "number" then
                itemQuality = quality
            end
            
            -- 使用新的格式序列化数据：物品ID、物品名称、玩家名称、分数、是否为许愿、时间戳、物品品质
                -- 使用分号代替竖线，避免与魔兽世界的转义代码冲突
                local chunkData = string.format(";i=%s,n=%s,f=%d,x=%d,p=%s,t=%02d:%02d,q=%d",
                    itemID,
                    safeItemName,
                    points,
                    isWish,
                    safePlayerName,
                    hour,
                    minute,
                    itemQuality
                )
            
            -- 发送当前批次数据，添加批次信息，使用冒号分隔批次信息
            -- 确保消息格式正确，让接收方能够正确解析为单个物品
            -- 修复：确保起始索引正确设置为最新物品的索引
            local message = string.format("%d:%d:%d%s",
                currentIndex,  -- 起始索引设为当前物品索引
                1,             -- 每次只发送1个物品
                totalItems,    -- 总物品数
                chunkData
            )
        
            SendAddonMessage("XY_LOOTLIST_SYNC", message, "RAID")
            
            -- 已移除：团长不再接收自己发送的数据
        end
        return  -- 发送单个物品后直接返回，不进行递归
    end
    
    -- 处理批量同步的情况
    while currentIndex <= totalItems do
        local chunkData = ""
        local itemsInChunk = 0
        
        -- 收集当前批次的数据（每次只发送一个物品）
        for i = currentIndex, math.min(currentIndex + chunkSize - 1, totalItems) do
            local lootItem = LootList[i]
            if lootItem then
                -- 从物品链接中提取物品ID，只发送关键信息
                local itemID = ExtractItemID(lootItem.itemLink)
                local points = lootItem.points or 0
                local isWish = lootItem.isWish and 1 or 0
                local safePlayerName = lootItem.playerName or ""
                local hour = 0
                local minute = 0
                if lootItem.timestamp then
                    if type(lootItem.timestamp) == "table" and lootItem.timestamp.hour and lootItem.timestamp.minute then
                        hour = lootItem.timestamp.hour
                        minute = lootItem.timestamp.minute
                    else
                        -- 对于数字格式时间戳，转换为时分格式
                        local timeStruct = date("*t", lootItem.timestamp)
                        hour = timeStruct.hour or 0
                        minute = timeStruct.min or 0
                    end
                end
                
                -- 替换可能导致解析问题的特殊字符
                safePlayerName = string.gsub(safePlayerName, "|", "||")  -- 转义竖线
                local safeItemName = lootItem.itemName or "未知物品"
                safeItemName = string.gsub(safeItemName, "|", "||")  -- 转义物品名称中的竖线
                
                -- 确保itemID不为空
                if not itemID or itemID == "" then
                    itemID = "0"
                end
                
                -- 获取物品品质信息
                local itemQuality = 5 -- 默认紫色史诗
                local itemName, itemLink, quality = GetItemInfo(itemID)
                if quality and type(quality) == "number" then
                    itemQuality = quality
                end
                
                -- 使用新的格式序列化数据：物品ID、物品名称、玩家名称、分数、是否为许愿、时间戳、物品品质
                -- 使用分号代替竖线，避免与魔兽世界的转义代码冲突
                local itemData = string.format(";i=%s,n=%s,f=%d,x=%d,p=%s,t=%02d:%02d,q=%d",
                    itemID,
                    safeItemName,
                    points,
                    isWish,
                    safePlayerName,
                    hour,
                    minute,
                    itemQuality
                )
                
                chunkData = chunkData .. itemData
                itemsInChunk = itemsInChunk + 1
            end
        end
        
        -- 发送当前批次数据，添加批次信息，使用冒号分隔批次信息
        local message = string.format("%d:%d:%d%s",
            currentIndex,
            itemsInChunk,
            totalItems,
            chunkData
        )
   
        SendAddonMessage("XY_LOOTLIST_SYNC", message, "RAID")
        
        -- 已移除：团长不再接收自己发送的数据
        
        -- 移动到下一批次
        currentIndex = currentIndex + chunkSize
        
        -- 小延迟以避免消息丢失
        if currentIndex <= totalItems then
            local delayFrame = CreateFrame("Frame")
            delayFrame.elapsed = 0
            delayFrame:SetScript("OnUpdate", function()
                this.elapsed = this.elapsed + arg1
                if this.elapsed >= 0.1 then
                    this:SetScript("OnUpdate", nil)
                    syncLootListBatch(currentIndex, totalItems)
                end
            end)
            return
        end
    end
end

-- 批量同步辅助函数，用于递归发送后续批次数据
function syncLootListBatch(startIndex, totalItems)
    local currentIndex = startIndex or 1
    local chunkSize = 1  -- 每次只发送1个物品，避免数据过长导致错误
    while currentIndex <= totalItems do
        local chunkData = ""
        local itemsInChunk = 0
        
        -- 收集当前批次的数据（每次只发送一个物品）
        for i = currentIndex, math.min(currentIndex + chunkSize - 1, totalItems) do
            local lootItem = LootList[i]
            if lootItem then
                -- 从物品链接中提取物品ID，只发送关键信息
                local itemID = ExtractItemID(lootItem.itemLink)
                local points = lootItem.points or 0
                local isWish = lootItem.isWish and 1 or 0
                local safePlayerName = lootItem.playerName or ""
                local hour = 0
                local minute = 0
                if lootItem.timestamp then
                    if type(lootItem.timestamp) == "table" and lootItem.timestamp.hour and lootItem.timestamp.minute then
                        hour = lootItem.timestamp.hour
                        minute = lootItem.timestamp.minute
                    else
                        -- 对于数字格式时间戳，转换为时分格式
                        local timeStruct = date("*t", lootItem.timestamp)
                        hour = timeStruct.hour or 0
                        minute = timeStruct.min or 0
                    end
                end
       
                safePlayerName = string.gsub(safePlayerName, "|", "||")  -- 转义竖线
                local safeItemName = string.gsub(lootItem.itemName or "未知物品", "|", "||")
                
                -- 获取物品品质信息
                local itemQuality = 5 -- 默认紫色史诗
                local itemName, itemLink, quality = GetItemInfo(itemID)
                if quality and type(quality) == "number" then
                    itemQuality = quality
                end
                
                local itemData = string.format(";i=%s,n=%s,f=%d,x=%d,p=%s,t=%02d:%02d,q=%d",
                    itemID,
                    safeItemName,
                    points,
                    isWish,
                    safePlayerName,
                    hour,
                    minute,
                    itemQuality
                )
                
                chunkData = chunkData .. itemData
                itemsInChunk = itemsInChunk + 1
            end
        end
        
        -- 发送当前批次数据，添加批次信息，使用冒号分隔批次信息
        local message = string.format("%d:%d:%d%s",
            currentIndex,
            itemsInChunk,
            totalItems,
            chunkData
        )
     
        SendAddonMessage("XY_LOOTLIST_SYNC",message, "RAID")
        
        -- 移动到下一批次
        currentIndex = currentIndex + chunkSize
        
        -- 小延迟以避免消息丢失
        if currentIndex <= totalItems then
            local delayFrame = CreateFrame("Frame")
            delayFrame.elapsed = 0
            delayFrame:SetScript("OnUpdate", function()
                this.elapsed = this.elapsed + arg1
                if this.elapsed >= 0.1 then
                    this:SetScript("OnUpdate", nil)
                    syncLootListBatch(currentIndex, totalItems)
                end
            end)
            return
        end
    end
end
-- 辅助函数：通过物品ID和品质创建物品链接
function CreateBasicItemLink(itemID, itemQuality)
    if not itemID or itemID == "" then
        return ""
    end
    
    -- 根据品质设置正确的颜色代码
    local qualityColor = "ffa335ee" -- 默认紫色
    
    if itemQuality == 5 then -- 橙色传说
        qualityColor = "ffff8000"
    elseif itemQuality == 4 then -- 紫色史诗
        qualityColor = "ffa335ee"
    elseif itemQuality == 3 then -- 蓝色精良
        qualityColor = "ff0070dd"
    elseif itemQuality == 2 then -- 绿色优秀
        qualityColor = "ff1eff00"
    elseif itemQuality == 1 then -- 白色普通
        qualityColor = "ffffffff"

    end
    
    -- 创建包含正确颜色的物品链接
    return "|c"..qualityColor.."|Hitem:"..itemID..":0:0:0|h[未知物品]|h|r"
end

-- LootList同步数据处理函数 - 所有玩家共用的统一逻辑
function receiveLootListSync(message)
    -- 解析消息头：起始索引:当前批次数量:总数量
    local startIndex, itemsCount, totalItems, itemData = string.match(message, "(%d+):(%d+):(%d+)(.*)")
    
    if not startIndex or not itemsCount or not totalItems then
        -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 同步数据格式错误！")
        return
    end
    
    startIndex = tonumber(startIndex)
    itemsCount = tonumber(itemsCount)
    totalItems = tonumber(totalItems)
    
    -- 确保LootList存在
    if not LootList then
        LootList = {}
    end

    -- 性能：先建 物品ID|玩家|物品名 键集合用于O(1)查重，避免每条同步物品都全表扫描并逐个ExtractItemID
    local lootDupKeySet = {}
    for i, existingItem in ipairs(LootList) do
        if existingItem then
            local eKey = tostring(ExtractItemID(existingItem.itemLink)) .. "|" .. tostring(existingItem.playerName) .. "|" .. tostring(existingItem.itemName)
            lootDupKeySet[eKey] = i
        end
    end

    -- 解析物品数据
    local itemsProcessed = 0
    
    -- 逐行解析物品数据块（以分号分隔）
    local pos = 1
    while pos <= string.len(itemData) do
        -- 查找下一个物品的起始位置
        local nextPos = string.find(itemData, ";", pos + 1)
        if not nextPos then
            -- 如果没有下一个分号，处理最后一个物品
            nextPos = string.len(itemData) + 1
        end
        
        -- 提取单个物品的数据块
        local itemDataBlock = string.sub(itemData, pos, nextPos - 1)
        pos = nextPos
        
        -- 尝试解析新格式的数据 (;i=物品ID,n=物品名称,f=分数,x=是否许愿,p=玩家名,t=时间戳)
        -- 处理可能以分号开头的情况
        local firstChar = string.sub(itemDataBlock, 1, 1)
        local secondChar = string.sub(itemDataBlock, 2, 2)
        
        if firstChar == "i" or (firstChar == ";" and secondChar == "i") then
            -- 如果以分号开头，跳过分号
            if firstChar == ";" then
                itemDataBlock = string.sub(itemDataBlock, 2)
            end
            -- 改进的解析逻辑，使用更可靠的方式提取各个字段
            local itemID = string.match(itemDataBlock, "i=([^,]+)")
            local itemName = string.match(itemDataBlock, "n=([^,]+)")
            local points = string.match(itemDataBlock, "f=(%d+)")
            local isWish = string.match(itemDataBlock, "x=(%d+)")
            local playerName = string.match(itemDataBlock, "p=([^,]+)")
            local timestamp = string.match(itemDataBlock, "t=(%d%d:%d%d)")
            
            if itemID and itemName and points and isWish and playerName and timestamp then
                -- 安全解码特殊字符
                playerName = string.gsub(playerName, "||", "|")
                points = tonumber(points) or 0
                isWish = tonumber(isWish) == 1
                
                -- 解析时间戳
                local hour, minute = string.match(timestamp, "(%d%d):(%d%d)")
                hour = tonumber(hour) or 0
                minute = tonumber(minute) or 0
                
                -- 解析物品品质信息（新增字段）
                local itemQuality = 5 -- 默认紫色史诗
                local qualityMatch = string.match(itemDataBlock, "q=(%d+)")
                if qualityMatch then
                    itemQuality = tonumber(qualityMatch) or 5
                end
                
                -- 创建包含正确颜色的物品链接
                local basicItemLink = CreateBasicItemLink(itemID, itemQuality)
                
                -- 完全按照团长发送的数据构建物品对象
                local lootItem = {
                    itemName = itemName,
                    itemLink = basicItemLink,
                    playerName = playerName,
                    points = points,
                    isWish = isWish,
                    timestamp = time() -- 使用Unix时间戳
                }
                
                -- 性能：用预建键集合O(1)查重（键=物品ID|玩家|物品名），替代每个物品全表扫描
                local dupKey = tostring(itemID) .. "|" .. tostring(playerName) .. "|" .. tostring(itemName)
                local existingIndex = lootDupKeySet[dupKey]
                local isDuplicate = false

                if existingIndex then
                    -- 键相同仍需校验时间条件，与原全表扫描逻辑保持一致
                    local existingTimestamp = LootList[existingIndex].timestamp
                    local isTimeMatch = false

                    if existingTimestamp then
                        if type(existingTimestamp) == "table" and existingTimestamp.hour and existingTimestamp.minute then
                            -- 旧格式：表格式时间戳 {hour, minute}
                            isTimeMatch = (existingTimestamp.hour == hour and existingTimestamp.minute == minute)
                        else
                            -- 新格式：数字格式时间戳 (Unix时间戳)
                            isTimeMatch = true -- 对于数字格式时间戳，不再比较具体时分，只比较物品ID、玩家名称和物品名称
                        end
                    end

                    if isTimeMatch then
                        -- 找到完全匹配的物品，但仍然更新，确保数据是最新的
                        isDuplicate = true
                    else
                        existingIndex = nil
                    end
                end
                
                if isDuplicate and existingIndex then
                    -- 更新现有物品，确保数据是最新的
                    LootList[existingIndex] = lootItem
                    itemsProcessed = itemsProcessed + 1
                else
                    -- 如果不是重复数据，则添加到列表中
                    -- 根据起始索引添加物品到正确位置，确保同步顺序正确
                    local insertIndex = table.getn(LootList) + 1
                    if startIndex and startIndex > insertIndex then
                        insertIndex = startIndex
                    end
                    lootItem.timestamp = time() -- 添加时间戳
                    table.insert(LootList, insertIndex, lootItem)
                    lootDupKeySet[dupKey] = insertIndex -- 新记录同步进键集合
                    itemsProcessed = itemsProcessed + 1
                end
            else
                XyTracker_Print("解析物品数据失败: " .. itemDataBlock, XyTracker_DebugLevel.ERROR)
            end
        -- 保持向后兼容性，支持旧格式的数据解析 (n=物品链接,f=分数,x=是否许愿,p=玩家名,t=时间戳)
        -- 注意：旧格式仍然使用竖线分隔
        elseif firstChar == "n" or (firstChar == ";" and secondChar == "n") then
            -- 如果以分号开头，跳过分号
            if firstChar == ";" then
                itemDataBlock = string.sub(itemDataBlock, 2)
            end
            -- 改进的解析逻辑，使用更可靠的方式提取各个字段
            local itemLink = string.match(itemDataBlock, "n=([^,]+)")
            local points = string.match(itemDataBlock, "f=(%d+)")
            local isWish = string.match(itemDataBlock, "x=(%d+)")
            local playerName = string.match(itemDataBlock, "p=([^,]+)")
            local timestamp = string.match(itemDataBlock, "t=(%d%d:%d%d)")
            
            if itemLink and points and isWish and playerName and timestamp then
                -- 安全解码特殊字符
                itemLink = string.gsub(itemLink, "||", "|")
                playerName = string.gsub(playerName, "||", "|")
                points = tonumber(points) or 0
                isWish = tonumber(isWish) == 1
                
                -- 解析时间戳
                local hour, minute = string.match(timestamp, "(%d%d):(%d%d)")
                hour = tonumber(hour) or 0
                minute = tonumber(minute) or 0
                
                -- 从物品链接中提取物品名称
                local itemName = ExtractItemName(itemLink)
                
                -- 完全按照团长发送的数据构建物品对象
                local lootItem = {
                    itemName = itemName,
                    itemLink = itemLink,
                    playerName = playerName,
                    points = points,
                    isWish = isWish,
                    timestamp = {hour = hour, minute = minute}
                }
                
                -- 性能：用预建键集合O(1)查重，替代每个物品全表扫描
                local dupKey = tostring(ExtractItemID(itemLink)) .. "|" .. tostring(playerName) .. "|" .. tostring(itemName)
                local existingIndex = lootDupKeySet[dupKey]
                local isDuplicate = false

                if existingIndex then
                    -- 键相同仍需校验时分，与原全表扫描逻辑保持一致
                    local existingTimestamp = LootList[existingIndex].timestamp
                    if existingTimestamp and type(existingTimestamp) == "table" and
                       existingTimestamp.hour == hour and existingTimestamp.minute == minute then
                        -- 找到完全匹配的物品，但仍然更新，确保数据是最新的
                        isDuplicate = true
                    else
                        existingIndex = nil
                    end
                end
                
                if isDuplicate and existingIndex then
                    -- 更新现有物品，确保数据是最新的
                    LootList[existingIndex] = lootItem
                    itemsProcessed = itemsProcessed + 1
                else
                    -- 如果不是重复数据，则添加到列表中
                    -- 根据起始索引添加物品到正确位置，确保同步顺序正确
                    local insertIndex = table.getn(LootList) + 1
                    if startIndex and startIndex > insertIndex then
                        insertIndex = startIndex
                    end
                    table.insert(LootList, insertIndex, lootItem)
                    lootDupKeySet[dupKey] = insertIndex -- 新记录同步进键集合
                    itemsProcessed = itemsProcessed + 1
                end
            else
                XyTracker_Print("解析旧格式物品数据失败: " .. itemDataBlock, XyTracker_DebugLevel.ERROR)
            end
        end
    end
    
    -- 清理nil值，确保LootList是连续的
    local cleanLootList = {}
    for _, item in ipairs(LootList) do
        if item then
            table.insert(cleanLootList, item)
        end
    end
    LootList = cleanLootList
    
    -- 添加调试信息，帮助排查同步问题
    XyTracker_Print("处理批次: 起始索引="..startIndex..", 处理物品数="..itemsProcessed..", 总物品数="..totalItems, XyTracker_DebugLevel.DEBUG)
    
    -- 检查是否已接收完所有数据
    local currentCount = table.getn(LootList)
    -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker调试] 当前LootList物品总数: "..currentCount)
    
    -- 如果已接收完所有数据或者当前索引已到达总数量，更新UI
    if currentCount >= totalItems or startIndex + itemsProcessed - 1 >= totalItems then
        -- 使用与团长完全相同的更新逻辑刷新UI
        XyTracker_UpdateLootList()
        XyTracker_Print("拾取列表已从团长同步！共"..currentCount.."个物品", XyTracker_DebugLevel.INFO)
    end
end

-- 保存拾取列表到独立变量
function XyTracker_SaveLootList()
    -- 确保SavedLootList存在且是一个新的空表
    SavedLootList = {}
    
    -- 深拷贝当前LootList数据
    local savedCount = 0
    local lootCount = table.getn(LootList)
    for i = 1, lootCount do
        local lootItem = LootList[i]
        -- 只保存有效的物品数据
        if lootItem and type(lootItem) == "table" and 
           lootItem.itemName and type(lootItem.itemName) == "string" and lootItem.itemName ~= "" and 
           lootItem.playerName and type(lootItem.playerName) == "string" and lootItem.playerName ~= "" then
            
            -- 创建保存的物品数据
            local savedItem = {
                itemName = tostring(lootItem.itemName),
                itemLink = lootItem.itemLink and tostring(lootItem.itemLink) or "",
                playerName = tostring(lootItem.playerName),
                points = type(lootItem.points) == "number" and lootItem.points or 0,
                isWish = type(lootItem.isWish) == "boolean" and lootItem.isWish or false,
                timestamp = {}
            }
            
            -- 正确深拷贝timestamp字段
            if lootItem.timestamp and type(lootItem.timestamp) == "table" then
                savedItem.timestamp.hour = type(lootItem.timestamp.hour) == "number" and lootItem.timestamp.hour or 0
                savedItem.timestamp.minute = type(lootItem.timestamp.minute) == "number" and lootItem.timestamp.minute or 0
            else
                savedItem.timestamp.hour = 0
                savedItem.timestamp.minute = 0
            end
            
            -- 添加到SavedLootList并计数
            table.insert(SavedLootList, savedItem)
            savedCount = savedCount + 1
        end
    end
    
    -- 简单显示保存成功消息
    DEFAULT_CHAT_FRAME:AddMessage("拾取列表已保存", XyTracker_DebugLevel.INFO)
end

-- 从保存的变量恢复拾取列表
function XyTracker_RestoreLootList()
    -- 检查是否有保存的数据
    local hasData = false
    local validItems = {}
    
    -- 确保SavedLootList存在
    if SavedLootList and type(SavedLootList) == "table" then
        -- 使用pairs遍历SavedLootList，处理稀疏数组问题
        for k, v in pairs(SavedLootList) do
            -- 只处理数值键和有效的物品数据
            if type(k) == "number" and v and type(v) == "table" and 
               v.itemName and type(v.itemName) == "string" and v.itemName ~= "" and 
               v.playerName and type(v.playerName) == "string" and v.playerName ~= "" then
                table.insert(validItems, v)
                hasData = true
            end
        end
    else
        -- 简单显示恢复失败原因
         DEFAULT_CHAT_FRAME:AddMessage("恢复失败因为: SavedLootList不存在或不是有效的表", XyTracker_DebugLevel.ERROR)
        return
    end
    
    if hasData then
        -- 清空当前LootList
        LootList = {}
        
        -- 深拷贝保存的数据
        for i, savedItem in ipairs(validItems) do
            local lootItem = {
                itemName = tostring(savedItem.itemName),
                itemLink = savedItem.itemLink and tostring(savedItem.itemLink) or "",
                playerName = tostring(savedItem.playerName),
                points = type(savedItem.points) == "number" and savedItem.points or 0,
                isWish = type(savedItem.isWish) == "boolean" and savedItem.isWish or false,
                timestamp = {}
            }
            
            -- 正确深拷贝timestamp字段
            if savedItem.timestamp and type(savedItem.timestamp) == "table" then
                lootItem.timestamp.hour = type(savedItem.timestamp.hour) == "number" and savedItem.timestamp.hour or 0
                lootItem.timestamp.minute = type(savedItem.timestamp.minute) == "number" and savedItem.timestamp.minute or 0
            else
                lootItem.timestamp.hour = 0
                lootItem.timestamp.minute = 0
            end
            
            table.insert(LootList, lootItem)
        end
        
        -- 更新UI显示
        XyTracker_UpdateLootList()
        
        -- 简单显示恢复成功消息
         DEFAULT_CHAT_FRAME:AddMessage("拾取列表已恢复", XyTracker_DebugLevel.INFO)
    else
        -- 简单显示恢复失败原因
         DEFAULT_CHAT_FRAME:AddMessage("恢复失败因为: 没有找到已保存的拾取列表数据", XyTracker_DebugLevel.ERROR)
    end
end

-- 保存许愿信息到独立变量
-- silent=true 时不打印提示（自动备份高频调用，避免刷屏）
function XyTracker_SaveWishList(silent)
    -- 确保XyArray存在
    if not XyArray then
        return
    end
    
    -- 创建或重置SavedWishList
    if not _G["SavedWishList"] then
        _G["SavedWishList"] = {}
    elseif type(_G["SavedWishList"]) ~= "table" then
        _G["SavedWishList"] = {}
    end
    
    -- 本地引用，用于更快的访问
    local SavedWishList = _G["SavedWishList"]
    
    -- 清空SavedWishList中的所有元素
    for k in pairs(SavedWishList) do
        SavedWishList[k] = nil
    end
    
    -- 添加版本控制信息
    SavedWishList.version = "1.3"
    SavedWishList.saveTime = time()
    
    -- 获取成员数量
    local memberCount = table.getn(XyArray)
    
    -- 深拷贝当前XyArray中的许愿数据
    for i = 1, memberCount do
        local memberInfo = XyArray[i]
        -- 只保存有效的成员数据
        if memberInfo and type(memberInfo) == "table" then
            -- 确保name字段存在且为非空字符串
            local name = memberInfo.name and type(memberInfo.name) == "string" and memberInfo.name ~= "" and memberInfo.name or "未知玩家"
            
            -- 创建保存的成员数据
            local savedInfo = {
                name = tostring(name),
                xy = memberInfo.xy and tostring(memberInfo.xy) or "",
                class = memberInfo.class and tostring(memberInfo.class) or "",
                dkp = memberInfo.dkp and tostring(memberInfo.dkp) or "0"
            }
            
            -- 添加到SavedWishList
            table.insert(SavedWishList, savedInfo)
        end
    end
    
    -- 创建备份表
    if not _G["XyTrackerData"] then
        _G["XyTrackerData"] = {}
    end
    
    _G["XyTrackerData"]["WishListBackup"] = {}
    local backup = _G["XyTrackerData"]["WishListBackup"]
    
    -- 备份数据
    for i, savedInfo in ipairs(SavedWishList) do
        if type(i) == "number" and savedInfo then
            backup[i] = {
                name = savedInfo.name,
                xy = savedInfo.xy,
                class = savedInfo.class,
                dkp = savedInfo.dkp
            }
        end
    end
    
    -- 简单显示保存成功消息
    if not silent then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 许愿列表已保存", XyTracker_DebugLevel.INFO)
    end
end

-- 从保存的变量恢复许愿信息
function XyTracker_RestoreWishList()
    -- 优先从 Imports 目录的文件备份恢复（需 SuperWoW，崩溃也不丢；
    -- restoringFromFile 标记防止文件恢复流程回调本函数造成递归）
    if XyTracker_Backup_RestoreFromFile
        and not (XyTrackerBackup and XyTrackerBackup.restoringFromFile)
        and XyTracker_Backup_RestoreFromFile() then
        return
    end
    -- 检查是否有保存的数据
    local hasData = false
    local validMembers = {}
    
    -- 尝试从多个来源恢复数据
    local wishList = nil
    
    -- 1. 首先尝试主数据
    if _G["SavedWishList"] and type(_G["SavedWishList"]) == "table" then
        local mainCount = 0
        for k, v in pairs(_G["SavedWishList"]) do
            if type(k) == "number" then
                mainCount = mainCount + 1
            end
        end
        
        if mainCount > 0 or (_G["SavedWishList"].version and _G["SavedWishList"].saveTime) then
            wishList = _G["SavedWishList"]
        end
    end
    
    -- 2. 如果主数据无效，尝试从备份中获取
    if not wishList then
        if _G["XyTrackerData"] and _G["XyTrackerData"]["WishListBackup"] and type(_G["XyTrackerData"]["WishListBackup"]) == "table" then
            local backupCount = 0
            for k, v in pairs(_G["XyTrackerData"]["WishListBackup"]) do
                if type(k) == "number" then
                    backupCount = backupCount + 1
                end
            end
            
            if backupCount > 0 then
                wishList = _G["XyTrackerData"]["WishListBackup"]
            end
        end
    end
    
    -- 检查数据有效性
    if not wishList or type(wishList) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 恢复失败因为: 无法获取有效数据")
        return
    end
    
    -- 遍历数据，处理稀疏数组问题
    for k, v in pairs(wishList) do
        -- 跳过元数据（如version和saveTime）
        if k ~= "version" and k ~= "saveTime" and k ~= "timestamp" and k ~= "metadata" and type(k) == "number" and v and type(v) == "table" then
            -- 放宽验证条件，确保能恢复尽可能多的数据
            local name = v.name and type(v.name) == "string" and v.name ~= "" and v.name or ("未知玩家_" .. tostring(k))
            
            table.insert(validMembers, {
                name = name,
                xy = v.xy and tostring(v.xy) or "",
                class = v.class and tostring(v.class) or "",
                dkp = v.dkp and tonumber(v.dkp) or 0
            })
            hasData = true
        end
    end
    
    if hasData then
        -- 创建名称到索引的映射，以便快速查找
        local nameToIndex = {}
        
        -- 恢复前先清空许愿表：避免上次副本的残留记录与备份数据合并混在一起
        -- （XyArray 重新赋值会使 getXyInfo 的名字缓存自动重建，安全）
        XyArray = {}
        
        -- 建立现有成员的映射
        local existingCount = table.getn(XyArray)
        for i = 1, existingCount do
            local memberInfo = XyArray[i]
            if memberInfo and memberInfo.name then
                nameToIndex[memberInfo.name] = i
            end
        end
        
        -- 恢复许愿信息
        for i, savedInfo in ipairs(validMembers) do
            if savedInfo and savedInfo.name then
                local name = savedInfo.name
                
                if nameToIndex[name] then
                    -- 如果玩家已经在XyArray中，更新他们的许愿信息
                    local index = nameToIndex[name]
                    XyArray[index].xy = tostring(savedInfo.xy or "")
                    if savedInfo.class and savedInfo.class ~= "" then
                        XyArray[index].class = tostring(savedInfo.class)
                    end
                    if savedInfo.dkp and type(savedInfo.dkp) == "number" then
                        XyArray[index].dkp = savedInfo.dkp
                    end
                else
                    -- 如果玩家不在XyArray中，添加新记录
                    local newInfo = {
                        name = tostring(name),
                        xy = tostring(savedInfo.xy or ""),
                        class = tostring(savedInfo.class or ""),
                        dkp = savedInfo.dkp and type(savedInfo.dkp) == "number" and savedInfo.dkp or 0
                    }
                    table.insert(XyArray, newInfo)
                end
            end
        end
        
        -- 更新UI显示
        if getglobal("XyTrackerFrame") then
            XyTrackerFrame:Show()
        end
        XyTracker_UpdateList()
        
        -- 简单显示恢复成功消息
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 许愿列表已恢复")
    else
        -- 简单显示恢复失败原因
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 恢复失败因为: 没有找到已保存的许愿信息数据")
    end
end
        

function XyTracker_OnAnnounceButtonClick()
    if NoXyList == "" then
        SendChatMessage("所有人都已经许愿", "RAID", this.language, nil);
    else
        SendChatMessage("以下人员未许愿，请尽快许愿：" .. NoXyList, "RAID", this.language, nil);
    end
end

-- 播报许愿信息的计时器
XyBroadcastTimer = nil
XyCurrentBroadcastIndex = 0
XyBroadcastList = {}

function XyTracker_OnBroadcastWishesButtonClick()
    -- 停止任何正在进行的播报
    if XyBroadcastTimer then
        XyBroadcastTimer:Cancel();
        XyBroadcastTimer = nil;
    end
    
    -- 保存当前语言设置，以便在计时器回调中使用
    local currentLanguage = this.language
    
    -- 准备要播报的列表（使用当前排序后的displayArray）
    local totalMembers = GetNumRaidMembers()
    local currentRaidMembers = {}
    
    if totalMembers and totalMembers > 0 then
        for i = 1, totalMembers do
            local name = GetRaidRosterInfo(i)
            currentRaidMembers[name] = true
        end
        
        -- 清空之前的列表
        XyBroadcastList = {}
        
        -- 创建一个只包含当前团队成员的临时数组（按当前排序顺序）
        if table.getn(XyArray) > 0 and totalMembers > 0 then
            for i = 1, table.getn(XyArray) do
                local info = XyArray[i]
                if currentRaidMembers[info["name"]] then
                    table.insert(XyBroadcastList, info)
                end
            end
        end
        
        -- 开始播报
        XyCurrentBroadcastIndex = 1
        -- 获取当前排序依据的中文描述
        local sortMethodText = "角色名"
        if Xy_SortOptions.method == "class" then
            sortMethodText = "职业"
        elseif Xy_SortOptions.method == "xy" then
            sortMethodText = "许愿"
        elseif Xy_SortOptions.method == "dkp" then
            sortMethodText = "分数"
        end
        -- 添加排序方向描述
        if Xy_SortOptions.itemway == "desc" then
            sortMethodText = sortMethodText .. "降序"
        else
            sortMethodText = sortMethodText .. "升序"
        end
        SendChatMessage("以|cffff0000" .. sortMethodText .. "|r顺序开始播报许愿：", "RAID", currentLanguage, nil);
        
        -- 创建计时器，每0.5秒发送一条消息
        XyBroadcastTimer = CreateFrame("Frame");
        XyBroadcastTimer.elapsed = 0;
        XyBroadcastTimer:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1;
            if this.elapsed >= 0.5 then
                this.elapsed = 0;
                -- 处理当前及后续可能为空的玩家，直到找到有内容的或结束
                while XyCurrentBroadcastIndex <= table.getn(XyBroadcastList) do
                    local info = XyBroadcastList[XyCurrentBroadcastIndex]
                    XyCurrentBroadcastIndex = XyCurrentBroadcastIndex + 1;
                    
                    -- 只播报有内容的许愿
                    if info and info["xy"] and info["xy"] ~= "---未许愿---" then
                        -- 按照角色名、职业、许愿、分数的格式播报，使用★播报许愿★格式避免重复警报
                        local msg = string.format("★播报许愿★%s(%s): %s [%s分]", info["name"], info["class"], info["xy"], info["dkp"]);
                        SendChatMessage(msg, "RAID", currentLanguage, nil);
                        break; -- 发送一条后等待下一个0.5秒
                    end
                    -- 如果是空内容，则继续循环处理下一个玩家，不等待
                end
                
                -- 检查是否所有玩家都已处理完
                if XyCurrentBroadcastIndex > table.getn(XyBroadcastList) then
                    -- 播报完成
                    SendChatMessage("许愿信息播报完毕！", "RAID", currentLanguage, nil);
                    this:Cancel();
                end
            end
        end);
        
        XyBroadcastTimer.Cancel = function()
            XyBroadcastTimer:SetScript("OnUpdate", nil);
            XyBroadcastTimer = nil;
        end;
    else
        SendChatMessage("你不在团队中，无法播报许愿信息！", "RAID", currentLanguage, nil);
    end
end

function XyTracker_OnExportButtonClick()
    -- 创建一个只包含当前团队成员的临时数组（与displayArray相同的逻辑）
    local totalMembers = GetNumRaidMembers()
    local currentRaidMembers = {}
    local displayArray = {}
    
    if totalMembers and totalMembers > 0 then
        for i = 1, totalMembers do
            local name = GetRaidRosterInfo(i)
            currentRaidMembers[name] = true
        end
        
        -- 从XyArray中筛选出当前团队成员
        if table.getn(XyArray) > 0 then
            for i = 1, table.getn(XyArray) do
                local info = XyArray[i]
                if currentRaidMembers[info["name"]] then
                    table.insert(displayArray, info)
                end
            end
        end
    end
    
    -- 如果没有团队成员，使用完整的XyArray
    if table.getn(displayArray) == 0 then
        displayArray = XyArray
    end
    
    -- 生成导出文本
    local csvText = ""
    local n = table.getn(displayArray)
    for i = 1, n do
        local xy = displayArray[i]["xy"]
        if not xy then
            xy = ""
        end
        csvText = csvText .. displayArray[i]["class"] .. "-" .. displayArray[i]["name"] .. "-" .. xy .. "-当前剩余:[" .. displayArray[i]["dkp"] .. "]分" .. "\n"
    end
    
    -- 设置导出文本并显示窗口
    getglobal("XyExportEdit"):SetText(csvText);
    getglobal("XyExportFrame"):Show();
end

function Xy_FixZero(num)
    if (num < 10) then
        return "0" .. num;
    else
        return num;
    end
end


-- 为指定玩家增加DKP点数
function XyAddDkp(player, score)
    -- 从UI元素获取玩家名称和分数（自定义分数增加功能）
    if not player then
        player = getglobal("XyAddMember"):GetText()
    end
    if not score then
        score = tonumber(getglobal("XyAddDkpFramePoint"):GetText())
    end
    
    if not player or not score then return end
    
    local info = getXyInfo(player)
    if info then
        info["dkp"] = tonumber(info["dkp"]) + score
        XyTracker_UpdateList()
        XyQuery(player, score)
        syncXy(player) -- 只同步该玩家
        
        -- 【重要】设置数据变更标记，确保在游戏退出时自动保存
        _G["XyTracker_SavedWishList_LastUpdate"] = time()
        -- 记录当前XyArray的实际大小，用于验证
        _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
    end
end

-- 为指定玩家扣除DKP点数
function XyMinusDkp(player, score)
    -- 从UI元素获取玩家名称和分数（自定义分数扣除功能）
    if not player then
        player = getglobal("XyMinusMember"):GetText()
    end
    if not score then
        score = tonumber(getglobal("XyMinusDkpFramePoint"):GetText())
    end
    
    if not player or not score then return end
    
    local info = getXyInfo(player)
    if info then
        info["dkp"] = tonumber(info["dkp"]) - score
        XyTracker_UpdateList()
        XyQuery(player, -score)
        syncXy(player) -- 只同步该玩家
        
        -- 【重要】设置数据变更标记，确保在游戏退出时自动保存
        _G["XyTracker_SavedWishList_LastUpdate"] = time()
        -- 记录当前XyArray的实际大小，用于验证
        _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
    end
end

-- 手动标记玩家许愿为已完成（兜底用）
-- 注意：xyBackup 只是会话内运行时字段，不随 SavedWishList/CSV 备份持久化（无需改备份模块）
function XyTracker_SetWishCompleted(name)
    if not name or name == "" then return end
    local info = getXyInfo(name)
    if not info then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 未找到玩家 " .. name .. " 的许愿信息")
        return
    end
    if info["xy"] and string.find(info["xy"], "已完成许愿") then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. name .. " 的许愿已是已完成状态")
        return
    end
    -- 备份当前许愿内容，供撤销使用
    info["xyBackup"] = info["xy"]
    info["xy"] = "|cFF00FFFF已完成许愿|r"
    XyTracker_UpdateList()
    syncXy(name) -- 只同步该玩家
    -- 设置数据变更标记，确保在游戏退出时自动保存
    _G["XyTracker_SavedWishList_LastUpdate"] = time()
    _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 已将 " .. name .. " 的许愿标记为已完成")
    -- 团队频道通报
    SendChatMessage(name .. " 已完成许愿（手动标记），当前剩余分数：[" .. tostring(info["dkp"]) .. "]", "RAID")
end

-- 撤销手动标记的已完成许愿
function XyTracker_UndoWishCompleted(name)
    if not name or name == "" then return end
    local info = getXyInfo(name)
    if not info then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 未找到玩家 " .. name .. " 的许愿信息")
        return
    end
    if not info["xyBackup"] then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] " .. name .. " 没有可撤销的标记记录")
        return
    end
    info["xy"] = info["xyBackup"]
    info["xyBackup"] = nil
    XyTracker_UpdateList()
    syncXy(name) -- 只同步该玩家
    -- 设置数据变更标记，确保在游戏退出时自动保存
    _G["XyTracker_SavedWishList_LastUpdate"] = time()
    _G["XyTracker_ArraySize_LastRecord"] = table.getn(XyArray)
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 已撤销 " .. name .. " 的已完成标记")
    -- 团队频道通报（带上恢复后的许愿内容）
    SendChatMessage(name .. " 的已完成标记已撤销，许愿恢复为：" .. tostring(info["xy"] or ""), "RAID")
end

-- 切换玩家许愿的已完成状态：已完成则撤销，否则标记
function XyTracker_ToggleWishCompleted(name)
    if not name or name == "" then return end
    local info = getXyInfo(name)
    if info and info["xy"] and string.find(info["xy"], "已完成许愿") then
        XyTracker_UndoWishCompleted(name)
    else
        XyTracker_SetWishCompleted(name)
    end
end

function XySortOptions(method)

    if (Xy_SortOptions.method and Xy_SortOptions.method == method) then
        if (Xy_SortOptions.itemway and Xy_SortOptions.itemway == "asc") then
            Xy_SortOptions.itemway = "desc";
        else
            Xy_SortOptions.itemway = "asc";
        end
    else
        Xy_SortOptions.method = method;
        Xy_SortOptions.itemway = "asc";
    end
    Xy_SortDkp();
    XyTracker_UpdateList();
end

function Xy_SortDkp()
    table.sort(XyArray, Xy_CompareDkps);
    -- 原地排序后必须重建名字索引缓存：缓存只按表引用/长度判断是否失效，
    -- 排序后名字会指向旧索引的他人行，getXyInfo校验失败后会重复插入同名行
    XyInfo_RebuildCache()
end

function Xy_CompareDkps(a1, a2)
    local method, way = Xy_SortOptions["method"], Xy_SortOptions["itemway"];
    local c1, c2 = a1[method], a2[method];
    
    -- 确保类型一致性，特别是对于dkp字段（可能从保存变量加载时变成了字符串）
    if method == "dkp" then
        -- 将可能是字符串的dkp值转换为数字
        c1 = tonumber(c1) or 0
        c2 = tonumber(c2) or 0
    end
    
    if (way == "asc") then
        return c1 < c2;
    else
        return c1 > c2;
    end
end

function ExtractItemName(xy)
    if not xy or type(xy) ~= "string" then
        return "", {}
    end
    
    -- 特殊处理：如果是未许愿状态，直接返回空字符串和空列表
    if xy == "---未许愿---" or xy == "" then
        return "", {}
    end
    
    -- 尝试提取所有物品名称
    local allItemNames = {}
    
    -- 检查是否包含物品链接
    if string.find(xy, "|Hitem:") then
        -- 提取物品链接中的物品名称
        for itemLink in string.gmatch(xy, "|Hitem:.-|h.-|h") do
            local itemName = string.match(itemLink, "|h%[(.-)%]|h")
            if itemName and itemName ~= "" then
                table.insert(allItemNames, itemName)
            end
        end
    else
        -- 处理非物品链接格式的许愿
        -- 1. 特别处理 [物品1][物品2] 这种常见格式
        local bracketPattern = "%[(.-)%]"
        local hasBracketItems = string.find(xy, bracketPattern)
        
        if hasBracketItems then
            for item in string.gmatch(xy, bracketPattern) do
                if item and item ~= "" then
                    table.insert(allItemNames, item)
                end
            end
        else
            -- 2. 处理其他分隔符的情况（逗号、顿号、空格等）
            local delimiters = {"，", ",", "、", " "} -- 支持常见的分隔符
            
            for _, delimiter in ipairs(delimiters) do
                if string.find(xy, delimiter) then
                    -- 分割字符串
                    local startIdx = 1
                    
                    while startIdx <= string.len(xy) do
                        local endIdx = string.find(xy, delimiter, startIdx)
                        if endIdx then
                            local item = string.sub(xy, startIdx, endIdx - 1)
                            item = string.trim(item)
                            if item and item ~= "" then
                                table.insert(allItemNames, item)
                            end
                            startIdx = endIdx + 1
                        else
                            local item = string.sub(xy, startIdx)
                            item = string.trim(item)
                            if item and item ~= "" then
                                table.insert(allItemNames, item)
                            end
                            break
                        end
                    end
                    
                    break -- 找到一个分隔符后就不再检查其他分隔符
                end
            end
        end
    end
    
    -- 如果找到了物品名称，返回第一个作为主物品名称，并返回所有物品名称列表
    if table.getn(allItemNames) > 0 then
        return allItemNames[1], allItemNames
    else
        -- 重要修复：如果没有找到任何物品名称，但原始xy不为空（且不是未许愿状态），
        -- 返回清理后的原始xy字符串，确保手动输入的许愿也能正确显示
        local cleanedXY = string.trim(xy)
        if cleanedXY and cleanedXY ~= "" and cleanedXY ~= "---未许愿---" then
            -- 简单清理：移除可能的多余字符，但保留主要内容
            cleanedXY = string.gsub(cleanedXY, "^%[+|%]+$", "")  -- 移除开头和结尾的方括号
            cleanedXY = string.trim(cleanedXY)
            return cleanedXY, {cleanedXY}
        end
        return "", {}
    end
end



function MarkItemAsCompleted(originalWish, completedItemName)
    if not originalWish or not completedItemName or type(originalWish) ~= "string" or type(completedItemName) ~= "string" then
        return originalWish
    end
    
    -- 清理物品名称，用于比较
    local cleanedCompletedName = safeCleanString(completedItemName)
    
    local newWish = originalWish
    local foundMatch = false
    local remainingItems = {}
    
    -- 1. 先检查是否包含物品链接格式
    if string.find(originalWish, "|Hitem:") then
        -- 物品链接提取正则表达式 - 优化支持所有颜色的物品
        local itemLinkPattern = "|c%x%x%x%x%x%x%x%x|Hitem:.-|h%[.-%]|h|r"
        local itemNamePattern = "|h%[(.-)%]|h"
        
        -- 收集所有物品链接，排除已完成的
        local startPos = 1
        local tempWish = originalWish
        
        while true do
            -- 查找下一个完整的物品链接（支持所有颜色）
            local linkStart, linkEnd = string.find(tempWish, itemLinkPattern, startPos)
            if not linkStart then
                -- 尝试更宽松的匹配模式
                linkStart, linkEnd = string.find(tempWish, "|Hitem:.-|h%[.-%]|h", startPos)
                if not linkStart then
                    break -- 没有更多链接了
                end
            end
            
            local fullItemLink = string.sub(tempWish, linkStart, linkEnd)

            -- 提取物品名称
            local itemName = string.match(fullItemLink, itemNamePattern)
            if itemName then
                local cleanedItemName = safeCleanString(itemName)
                
                -- 使用模糊比较，增加匹配的可能性
                if cleanedItemName == cleanedCompletedName or 
                   string.find(cleanedItemName, cleanedCompletedName, 1, true) or 
                   string.find(cleanedCompletedName, cleanedItemName, 1, true) then
                    foundMatch = true
                else
                    table.insert(remainingItems, fullItemLink)
                end
            else
                -- 如果无法提取物品名称，保留原始链接
                table.insert(remainingItems, fullItemLink)
            end
            
            startPos = linkEnd + 1
        end
        
        -- 构建新的许愿字符串
        if foundMatch then
            if table.getn(remainingItems) > 0 then
                newWish = "|cFF00FFFF【已完成许愿】|r" .. table.concat(remainingItems)
            else
                newWish = "|cFF00FFFF【已完成许愿】|r"
            end
        end
    else
        -- 2. 尝试处理 [物品1][物品2] 这种常见格式
        if not foundMatch then
            local itemPattern = "%[(.-)%]"
            local hasBracketItems = string.find(originalWish, itemPattern)
            
            if hasBracketItems then
                -- 收集所有中括号包裹的物品，排除已完成的
                for item in string.gmatch(originalWish, itemPattern) do
                    if item and item ~= "" then
                        local cleanedItemName = safeCleanString(item)
                        if cleanedItemName == cleanedCompletedName or 
                           string.find(cleanedItemName, cleanedCompletedName, 1, true) or 
                           string.find(cleanedCompletedName, cleanedItemName, 1, true) then
                            foundMatch = true
                        else
                            table.insert(remainingItems, "["..item.."]")
                        end
                    end
                end
                
                -- 构建新的许愿字符串
                if foundMatch then
                    if table.getn(remainingItems) > 0 then
                        newWish = "|cFF00FFFF【已完成许愿】|r" .. table.concat(remainingItems)
                    else
                        newWish = "|cFF00FFFF【已完成许愿】|r"
                    end
                end
            end
        end
        
        -- 3. 如果上面两种格式都没找到匹配，尝试处理其他分隔符的情况
        if not foundMatch then
            -- 分割许愿文本（支持多种分隔符）
            local delimiters = {"，", ",", "、", " "} -- 支持常见的分隔符
            local matchedDelimiter = nil
            
            -- 查找使用的分隔符
            for _, delimiter in ipairs(delimiters) do
                if string.find(originalWish, delimiter) then
                    matchedDelimiter = delimiter
                    break
                end
            end
            
            if matchedDelimiter then
                -- 分割字符串并收集未完成的物品
                local items = {}
                local startIdx = 1
                local tempStr = originalWish
                
                while startIdx <= string.len(tempStr) do
                    local endIdx = string.find(tempStr, matchedDelimiter, startIdx)
                    if endIdx then
                        local item = string.sub(tempStr, startIdx, endIdx - 1)
                        item = string.trim(item)
                        if item and item ~= "" then
                            table.insert(items, item)
                        end
                        startIdx = endIdx + 1
                    else
                        local item = string.sub(tempStr, startIdx)
                        item = string.trim(item)
                        if item and item ~= "" then
                            table.insert(items, item)
                        end
                        break
                    end
                end
                
                -- 过滤出未完成的物品
                for _, item in ipairs(items) do
                    local cleanedItemName = safeCleanString(item)
                    if cleanedItemName == cleanedCompletedName or 
                       string.find(cleanedItemName, cleanedCompletedName, 1, true) or 
                       string.find(cleanedCompletedName, cleanedItemName, 1, true) then
                        foundMatch = true
                    else
                        table.insert(remainingItems, item)
                    end
                end
                
                -- 构建新的许愿字符串
                if foundMatch then
                    if table.getn(remainingItems) > 0 then
                        newWish = "|cFF00FFFF【已完成许愿】|r" .. table.concat(remainingItems, matchedDelimiter)
                    else
                        newWish = "|cFF00FFFF【已完成许愿】|r"
                    end
                end
            end
        end
        
        -- 4. 最后尝试直接匹配整个字符串，处理单个物品或特殊情况
        if not foundMatch then
            local cleanedOriginalWish = safeCleanString(originalWish)
            if cleanedOriginalWish == cleanedCompletedName or 
               string.find(cleanedOriginalWish, cleanedCompletedName, 1, true) or 
               string.find(cleanedCompletedName, cleanedOriginalWish, 1, true) then
                foundMatch = true
                newWish = "|cFF00FFFF【已完成许愿】|r"
            end
        end
    end
    
    -- 返回修改后的许愿（如果有匹配的话），否则返回原始许愿
    return foundMatch and newWish or originalWish
end

function string.trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- 安全的字符串清理函数（这是重复定义，已被重命名以避免冲突）

-- 合并 江湖任我行@乌龟服-拉&风 的修改
--加Atlas tooltip 提示许愿人数...
if AtlasLootTooltip then
    Xytooltip = CreateFrame("Frame", "Xytooltip", AtlasLootTooltip)
    Xytooltip:SetScript("OnShow", function()
        if not IsInRaid() and not IsInGroup() then return end
        local Itemname = getglobal("AtlasLootTooltipTextLeft1"):GetText()
        local namelist
        if Itemname then 
        namelist = XYLIST1(Itemname)
        end
    
        if namelist then
            AtlasLootTooltip:AddLine(namelist)
        end
        AtlasLootTooltip:Show()
    end)

    Xytooltip:SetScript("OnHide", function()
        AtlasLootTooltip:Hide()
    end)
end
--加物品 Gametooltip 提示许愿人数和玩家许愿信息...
-- 修复GameTooltip绑定，保留对物品许愿信息的显示，并添加玩家许愿信息显示
if GameTooltip then
    Xytooltip2 = CreateFrame("Frame", "Xytooltip2", GameTooltip)
    Xytooltip2:SetScript("OnShow", function()
        if not IsInRaid() and not IsInGroup() then return end
        -- 检查是否已经处理过，避免重复添加
        if GameTooltip.XYProcessed then
            return
        end

        local text = getglobal("GameTooltipTextLeft1"):GetText() or ""

        -- 添加辅助函数：清理字符串中的颜色代码
        local function stripColorCodes(str)
            if not str then return "" end
            -- 移除颜色代码 |cffRRGGBB
            str = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
            -- 移除颜色结束标记 |r
            str = string.gsub(str, "|r", "")
            -- 移除其他可能的控制字符
            str = string.gsub(str, "|H.-|h", "")
            str = string.gsub(str, "|h", "")
            return str
        end

        -- 添加辅助函数：提取纯玩家名称，过滤掉军衔信息、换行和称号
        local function extractPlayerName(str)
            if not str then return "" end

            -- 首先移除颜色代码
            local cleanStr = stripColorCodes(str)

            -- 移除换行符
            cleanStr = string.gsub(cleanStr, "\n", " ")

            -- 过滤掉军衔信息，格式如[中士]、[军士长]等
            -- 匹配[...]格式的内容并移除
            cleanStr = string.gsub(cleanStr, "%[.-%]", "")

            -- 移除前后空白字符
            cleanStr = string.gsub(cleanStr, "^%s*(.-)%s*$", "%1")

            -- 处理"军衔 名字 称号"或"军衔 名字"格式，提取中间的名字部分
            local parts = {}
            -- 避免使用string.gmatch，使用string.gsub和string.match来分割字符串
            local tempStr = cleanStr
            while tempStr do
                local firstPart, remaining = string.match(tempStr, "([^%s]+)(.*)")
                if firstPart then
                    table.insert(parts, firstPart)
                    tempStr = string.gsub(remaining, "^%s*", "")
                    if tempStr == "" then
                        tempStr = nil
                    end
                else
                    tempStr = nil
                end
            end

            -- 如果有多个部分，取中间的部分作为名字
            -- 如果只有一个部分，直接返回

            local partsCount = table.getn(parts)
            if partsCount == 1 then
                return parts[1]
            elseif partsCount >= 2 then
                -- 对于"军衔 名字 称号"格式，返回中间的名字
                -- 对于"军衔 名字"格式，返回第二个部分
                return parts[2]
            end

            return cleanStr
        end

        -- 首先尝试作为物品名查询许愿信息
        local namelist = XYLIST1(text)

        -- 如果没有找到物品的许愿信息，尝试作为玩家名查询
        if not namelist then
            -- 收集 GameTooltip 全部行的去颜色码文本，用于在 L1 被称号/军衔污染时反向匹配 XyArray 中真实玩家名
            local fullText = stripColorCodes(text)
            for i = 2, GameTooltip:NumLines() do
                local lineText = getglobal("GameTooltipTextLeft"..i):GetText() or ""
                fullText = fullText .. " " .. stripColorCodes(lineText)
            end

            -- 检查是否是玩家（通常会有职业、等级等信息）
            local isPlayer = false
            for i = 2, GameTooltip:NumLines() do
                local lineText = getglobal("GameTooltipTextLeft"..i):GetText() or ""
                -- 检查是否包含职业、等级等玩家特征信息
                if string.find(lineText, "战士") or string.find(lineText, "法师") or
                   string.find(lineText, "牧师") or string.find(lineText, "猎人") or
                   string.find(lineText, "盗贼") or string.find(lineText, "圣骑士") or
                   string.find(lineText, "德鲁伊") or string.find(lineText, "萨满祭司") or
                   string.find(lineText, "术士") then
                    isPlayer = true
                    break
                end
            end
            -- 如果是玩家，查询并显示许愿信息
            if isPlayer then
                -- 反向匹配：直接从 XyArray 里找一个真实 player name 出现在 tooltip 文本中。
                -- 这样不论 L1 是 "名字"、"名字 称号"、"名字 [军衔]" 还是 "名字 称号 [军衔]" 都能命中。
                if XyArray and type(XyArray) == "table" then
                    for i = 1, table.getn(XyArray) do
                        local candidate = XyArray[i] and XyArray[i]["name"]
                        if candidate and candidate ~= "" and string.find(fullText, candidate, 1, true) then
                            namelist = XYLISTbyPlayer(candidate)
                            if namelist then break end
                        end
                    end
                end
                -- 兜底：保留旧的 extractPlayerName 路径，处理极端未在 XyArray 中的单位
                if not namelist then
                    local cleanPlayerName = extractPlayerName(text)
                    namelist = XYLISTbyPlayer(cleanPlayerName)
                end
            end
        end

        if namelist then
            GameTooltip:AddLine(namelist)
            GameTooltip:Show()
        end

        -- 设置处理标记,避免重复处理
        GameTooltip.XYProcessed = true
    end)

    Xytooltip2:SetScript("OnHide", function()
        -- 清除临时标记，允许下次查看时重新显示信息
        GameTooltip.XYProcessed = nil
    end)
end
--加点击物品 tooltip 提示许愿人数...
if ItemRefTooltip then
    Xytooltip3 = CreateFrame("Frame", "Xytooltip3", ItemRefTooltip)
    Xytooltip3:SetScript("OnShow", function()
        if not IsInRaid() and not IsInGroup() then return end
        local Itemname = getglobal("ItemRefTooltipTextLeft1"):GetText()
        local namelist
        if Itemname then 
        namelist = XYLIST1(Itemname)
        end
        --print(Itemname)
        --print(namelist)
        if namelist then
            ItemRefTooltip:AddLine(namelist)
        end
        ItemRefTooltip:Show()
    end)

    Xytooltip3:SetScript("OnHide", function()
        -- 移除直接调用ItemRefTooltip:Hide()的代码，避免干扰默认的物品链接点击行为
        -- ItemRefTooltip:Hide()
    end)
end
function ClasstoColor(class)
    if class =='战士' then return "|cffC79C6E"
    elseif  class =='萨满祭司' then return "|cff2773FF"
    elseif class =='德鲁伊' then return "|cffFF7D0A"
    elseif class =='盗贼' then return "|cffFFF569"
    elseif class =='法师' then return "|cff69CCFF"
    elseif class =='圣骑士' then return "|cffF58CBA"
    elseif class =='牧师' then return "|cffFFFFFF"
    elseif class =='术士' then return "|cff9482C9"
    elseif class =='猎人' then return "|cffABD473"
    end
  end
  
  
  
  function XYLIST1(Iname)    
      --by qtz tooltip提示许愿人数 ,返回许愿该装备的许愿名单.没有就返回nil   
      if XyArray ~=nil and Iname and Iname ~= "" then
        local n = table.getn(XyArray)
        local i,name,xy,class,color
        local num = 0
        local p = 0
        local itemname = ""
        local XYID,NOW,xy_name
        --local itemtable = {}
        
        -- 防止重复显示的临时标记
        if GameTooltip.XYProcessed and GameTooltip.XYProcessed == Iname then
          return nil
        end
        GameTooltip.XYProcessed = Iname
              
        -- 获取当前团队或队伍成员列表
        local currentMembers = {}
        
        -- 1. 检查团队成员（已移除5人小队许愿支持，仅统计团队）
        local totalRaidMembers = GetNumRaidMembers()
        if totalRaidMembers and totalRaidMembers > 0 then
            for i = 1, totalRaidMembers do
                local raidName = GetRaidRosterInfo(i)
                if raidName then
                    currentMembers[raidName] = true
                end
            end
        else
            -- 2. 不在团队时只显示自己
            local playerName = UnitName("player")
            if playerName then
                currentMembers[playerName] = true
            end
        end
              
        for i = 1, n do
          name = XyArray[i]["name"]
          xy = XyArray[i]["xy"] 
          if not xy then
            xy = ""
          end            

          -- 修复：使用更可靠的方式检测物品是否被许愿
          local isWished = false
          
          -- 方式1：安全检查物品链接格式的匹配（转义特殊字符）
          if string.find(xy, Iname, 1, true) then
            isWished = true
          end
          
          -- 只显示当前在团队或队伍中的玩家
          if isWished and currentMembers[name] then
            num = num+1            
            class = XyArray[i]["class"]
            color = ClasstoColor(XyArray[i]["class"]) 
            -- 安全获取dkp值，如果为nil则使用默认值0
            local dkpValue = XyArray[i]["dkp"] or 0
            
            if p == 3 then
              itemname = itemname.. "\n "..color..name .. "|r["..dkpValue .."分]"
              p=0
            else  
              itemname = itemname.. " "..color..name .. "|r["..dkpValue .."分]"
            end
            p = p+1
            NOW = Iname -- 设置为当前查询的物品名称
          end
        end
        
        if itemname ~="" then
          return "\n XY有:"..itemname.. "|cff9FFFA0".."\n  --共("..num..")人许愿--\n|r"
        else
          -- 即使没有找到许愿信息，也要清除临时标记，避免影响下次显示
          GameTooltip.XYProcessed = nil
          return nil   
        end        
      end
      
      -- 如果XyArray为nil或没有找到玩家的许愿信息，返回nil
      return nil
  end          

  
  --通过玩家名字查询许愿和许愿人数
  
  -- 简单函数：直接返回玩家的许愿内容
  function XY_GetPlayerWish(playername)
      if XyArray ~= nil then
        local n = table.getn(XyArray)
        local i, name, xy
        
        -- 确保playername不为空
        if not playername or playername == "" then
          return nil
        end
        
        -- 移除可能的空格
        playername = string.match(playername, "(%S+)") or playername
        
        -- 查找指定玩家的许愿信息
        for i = 1, n do
          name = XyArray[i]["name"]
          if name == playername then
            xy = XyArray[i]["xy"]
            
            -- 直接返回玩家的许愿内容
            if xy and xy ~= "" and xy ~= "---未许愿---" then
              return xy
            else
              return nil
            end
          end
        end
      end
      
      -- 如果XyArray为nil或没有找到玩家的许愿信息，返回nil
      return nil
  end
  
  function XYLISTbyPlayer(playername)
    local n = table.getn(XyArray)
    for i = 1, n do
        local name = XyArray[i]["name"]
        local xy = XyArray[i]["xy"]
        local dkpValue = XyArray[i]["dkp"] or 0

        if playername == name then
            if not xy then
                return "---未许愿---" 
            else
                -- 统计每个物品的重复许愿次数
                local formattedXY = xy
                
                -- 提取所有物品链接或名称
                local items = {}
                
                -- 匹配物品链接格式 [物品名] 或带颜色代码的物品链接
                local function extractItems(text)
                    local foundItems = {}
                    -- 匹配 [物品名] 格式
                    for item in string.gmatch(text, "%[([^%]]+)%]") do
                        table.insert(foundItems, item)
                    end
                    -- 如果没有找到标准格式，尝试分割文本中的空格分隔项
                    if table.getn(foundItems) == 0 then
                        for item in string.gmatch(text, "%S+") do
                            table.insert(foundItems, item)
                        end
                    end
                    return foundItems
                end
                
                local playerItems = extractItems(xy)
                
                -- 统计每个物品的重复许愿次数
                for _, item in ipairs(playerItems) do
                    local count = 0
                    -- 遍历所有玩家统计该物品的许愿次数
                    for j = 1, n do
                        local otherXY = XyArray[j]["xy"]
                        if otherXY and string.find(otherXY, item, 1, true) then
                            count = count + 1
                        end
                    end
                    
                    -- 只在数量大于1时添加计数显示
                    if count > 1 then
                        -- 替换原始物品为带计数的版本，计数部分使用cffffff00颜色
                        formattedXY = string.gsub(formattedXY, "%["..item.."%]", "["..item.."]|cffffff00("..count..")|r")
                    end
                end
                
                return "许愿: "..formattedXY .. " |cffffff00[" .. dkpValue .. "分]|r"   
            end
        end
    end
 end

-- 全局变量存储自定义的Starttext
local CustomStarttext = nil

-- 初始化时从XyTrackerOptions加载自定义欢迎文本
function XyTracker_LoadCustomStarttext()
    if XyTrackerOptions and XyTrackerOptions.CustomStarttext then
        CustomStarttext = XyTrackerOptions.CustomStarttext
        -- 调试信息
        -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 成功加载自定义欢迎文本")
    end
end

-- 保存自定义欢迎文本到XyTrackerOptions
function XyTracker_SaveCustomStarttext()
    if CustomStarttext and CustomStarttext ~= "" then
        -- 确保XyTrackerOptions已初始化
        InitializeXyTrackerOptions()
        XyTrackerOptions.CustomStarttext = CustomStarttext
        -- 调试信息
        -- DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 自定义欢迎文本已保存")
    end
end

-- 显示编辑Starttext的输入框
function XyTracker_ShowStarttextEditBox()
    -- 检查是否有权限（团长模式或未开团）
    if not IsLeader and XyInProgress then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 只有团长或未开团时才能编辑欢迎文本")
        return
    end
    
    -- 创建或获取编辑框
    local editBox = getglobal("XyTrackerStarttextEditBox")
    if not editBox then
        -- 创建编辑框窗口
        local frame = CreateFrame("Frame", "XyTrackerStarttextEditBoxFrame", UIParent)
        frame:SetWidth(400)
        frame:SetHeight(300)
        frame:SetPoint("CENTER", 0, 0)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    
    -- 设置背景和边框，与主界面保持一致
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        tileSize = 32,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetBackdropColor(0, 0, 0); -- 纯黑色，与主界面保持一致
    frame:SetBackdropBorderColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, 1); -- 红色边框，与主界面保持一致
    
        
        -- 窗口标题
        local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -30)
        title:SetText("编辑欢迎文本")
        
        -- 编辑框
        editBox = CreateFrame("EditBox", "XyTrackerStarttextEditBox", frame)
        editBox:SetWidth(360)
        editBox:SetHeight(150)
        editBox:SetPoint("TOP", frame, "TOP", 0, -50)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(true)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        
        -- 保存按钮
        local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        saveButton:SetWidth(80)
        saveButton:SetHeight(22)
        saveButton:SetPoint("BOTTOM", frame, "BOTTOM", -50, 15)
        saveButton:SetText("保存")
        saveButton:SetScript("OnClick", function() 
            local newText = editBox:GetText()
            if newText and newText ~= "" then
                CustomStarttext = newText
                -- 调用保存函数
                XyTracker_SaveCustomStarttext()
                DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 欢迎文本已更新并保存")
            end
            frame:Hide()
        end)
        
        -- 取消按钮
        local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        cancelButton:SetWidth(80)
        cancelButton:SetHeight(22)
        cancelButton:SetPoint("BOTTOM", frame, "BOTTOM", 50, 15)
        cancelButton:SetText("取消")
        cancelButton:SetScript("OnClick", function() frame:Hide() end)
    end
    
    -- 设置编辑框的默认内容
    local defaultText = " 参与本次副本必须同意以下副本规则，参与活动表示接受：\n 1.本次副本内装备分配以许愿为准。\n 2.中途跳车自愿接受封禁30天规则。\n 3.所有事宜最终解释权归团长所有。"
    editBox:SetText(CustomStarttext or defaultText)
    
    -- 显示编辑框窗口
    getglobal("XyTrackerStarttextEditBoxFrame"):Show()
end

-- 获取当前的Starttext（自定义或默认）
function XyTracker_GetCurrentStarttext()
    -- 优先从XyTrackerOptions获取，确保使用最新保存的值
    local startText = XyTrackerOptions and XyTrackerOptions.CustomStarttext or CustomStarttext
    return startText or " 参与本次副本必须同意以下副本规则，参与活动表示接受：\n 1.本次副本内装备分配以许愿为准。\n 2.中途跳车自愿接受封禁30天规则。\n 3.所有事宜最终解释权归团长所有。"
end

-- 获取职业颜色
function XYT_GetClassColor(class)
	if not class then return nil; end
	
	-- 职业颜色映射
	local classColors = {
		["战士"] = "\124cffC79C6E",
		["萨满祭司"] = "\124cff0070DE",
		["猎人"] = "\124cffABD473",
		["盗贼"] = "\124cffFFF569",
		["牧师"] = "\124cffFFFFFF",
		["死亡骑士"] = "\124cffC41F3F",
		["圣骑士"] = "\124cffF58CBA",
		["术士"] = "\124cff9482C9",
		["法师"] = "\124cff69CCF0",
		["德鲁伊"] = "\124cffFF7D0A",
	};
	
	-- 处理职业名称的简写形式
	local className = class;
	if string.find(class, "战士") then className = "战士";
	elseif string.find(class, "萨满祭司") then className = "萨满祭司";
	elseif string.find(class, "猎人") then className = "猎人";
	elseif string.find(class, "盗贼") then className = "盗贼";
	elseif string.find(class, "牧师") then className = "牧师";
	elseif string.find(class, "圣骑士") then className = "圣骑士";
	elseif string.find(class, "术士") then className = "术士";
	elseif string.find(class, "法师") then className = "法师";
	elseif string.find(class, "德鲁伊") then className = "德鲁伊";
	end
	
	return classColors[className];
end



