-- XyTracker 品质筛选模块

-- 初始化配置
local function InitConfig()
    -- 调用统一的初始化函数
    InitializeXyTrackerOptions()
end

-- 获取品质配置信息表
local function GetQualityInfo()
    return {
        {name = "Orange", color = {r = 1, g = 0.5, b = 0}, label = "橙", index = 5, xPos = 0},
        {name = "Purple", color = {r = 0.8, g = 0.3, b = 0.9}, label = "紫", index = 4, xPos = 40},
        {name = "Blue", color = {r = 0, g = 0.5, b = 1}, label = "蓝", index = 3, xPos = 80},
        {name = "Green", color = {r = 0, g = 1, b = 0}, label = "绿", index = 2, xPos = 120},
        {name = "White", color = {r = 1, g = 1, b = 1}, label = "白", index = 1, xPos = 160}
    };
end

-- 创建或获取主框架
local function GetOrCreateMainFrame()
    local mainFrame = getglobal("XyTrackerLootListFrame");
    if not mainFrame then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker错误] 主框架未找到，请先打开XyTracker窗口。", 1, 0, 0);
        return nil;
    end
    return mainFrame;
end

-- 创建或获取筛选框架
local function GetOrCreateFilterFrame(mainFrame)
    local filterFrame = getglobal("XyTrackerQualityFilterFrame");
    if not filterFrame then
        filterFrame = CreateFrame("Frame", "XyTrackerQualityFilterFrame", mainFrame);
    end
    
    -- 设置框架位置和大小
    local titleFrame = getglobal("XyTrackerLootListFrameTitle");
    if titleFrame then
        filterFrame:ClearAllPoints();
        filterFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 260, -5);
    else
        filterFrame:ClearAllPoints();
        filterFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 260, -25);
    end
    
    -- 在WoW 1.12中使用兼容的设置方式，分别设置宽度和高度
    filterFrame:SetWidth(300);
    filterFrame:SetHeight(20);
    filterFrame:Show();
    
    -- 确保框架是可交互的
    filterFrame:EnableMouse(false); -- 让鼠标事件穿透到复选框
    
    return filterFrame;
end

-- 创建或更新品质筛选UI元素 - 修复复选框交互问题
local function CreateOrUpdateQualityUI(filterFrame, forceCreate, showDebug)
    local qualities = GetQualityInfo();

    -- 遍历所有品质类型，创建或修复复选框和文本标签
    for _, quality in ipairs(qualities) do
        local checkBoxName = quality.name .. "QualityCheck";
        local checkBox = getglobal(checkBoxName);

        -- 创建或修复复选框
        if not checkBox or forceCreate then
            if not checkBox then
                -- 使用标准按钮模板创建复选框
                checkBox = CreateFrame("CheckButton", checkBoxName, filterFrame, "OptionsCheckButtonTemplate");
                if showDebug and forceCreate then
                    DEFAULT_CHAT_FRAME:AddMessage("  创建了缺失的复选框: " .. checkBoxName, 0.5, 1, 0.5);
                end
            else
                if showDebug and forceCreate then
                    DEFAULT_CHAT_FRAME:AddMessage("  复选框已存在: " .. checkBoxName, 0.5, 1, 0.5);
                end
            end
        end

        -- 重新设置复选框属性
        checkBox:ClearAllPoints();
        checkBox:SetPoint("LEFT", filterFrame, "LEFT", quality.xPos, 0);

        -- 设置复选框大小，确保有足够的点击区域
        checkBox:SetWidth(20);
        checkBox:SetHeight(20);
        
        -- 确保复选框的状态与配置一致
        checkBox:SetChecked(XyTrackerOptions.QualityFilters[quality.index] or false);
        
        -- 设置点击事件
        checkBox:SetScript("OnClick", function()
            if _G["XyTracker_FilterQualityUpdate"] then
                _G["XyTracker_FilterQualityUpdate"]();
            end
        end);
        
        -- 确保复选框的背景和选中纹理正确显示
        if checkBox.SetNormalTexture then
            checkBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
        end
        if checkBox.SetPushedTexture then
            checkBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
        end
        if checkBox.SetHighlightTexture then
            checkBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
        end
        
        -- 设置明确的点击区域，确保与显示区域一致
        checkBox:SetHitRectInsets(0, 0, 0, 0);
        
        -- 再次确认复选框的大小和可见性
        checkBox:SetWidth(20);
        checkBox:SetHeight(20);
        checkBox:Show(); -- 确保显示
        
        -- 创建或修复文本标签
        local textName = quality.name .. "QualityText";
        local textLabel = getglobal(textName);
        
        if not textLabel or forceCreate then
            if not textLabel then
                textLabel = filterFrame:CreateFontString(textName, "ARTWORK", "GameFontNormalSmall");
                if showDebug and forceCreate then
                    DEFAULT_CHAT_FRAME:AddMessage("  创建了缺失的文本标签: " .. textName, 0.5, 1, 0.5);
                end
            else
                if showDebug and forceCreate then
                    DEFAULT_CHAT_FRAME:AddMessage("  文本标签已存在: " .. textName, 0.5, 1, 0.5);
                end
            end
        end
        
        -- 重新设置文本标签属性
        textLabel:ClearAllPoints();
        -- 增加间距，确保文本不会覆盖复选框的点击区域
        textLabel:SetPoint("LEFT", checkBox, "RIGHT", 5, 0);
        textLabel:SetText(quality.label);
        textLabel:SetTextColor(quality.color.r, quality.color.g, quality.color.b);
        
        -- 确保文本标签在复选框下方，不会干扰点击事件
        textLabel:SetDrawLayer("ARTWORK");
        
        textLabel:Show(); -- 确保显示
    end
    
    -- 添加冗余的显示逻辑，确保所有UI元素都可见
    for _, quality in ipairs(qualities) do
        local checkBox = getglobal(quality.name .. "QualityCheck");
        local textLabel = getglobal(quality.name .. "QualityText");
        
        if checkBox then checkBox:Show(); end
        if textLabel then textLabel:Show(); end
    end
    
    -- 强制更新筛选状态
    if _G["XyTracker_FilterQualityUpdate"] then
        _G["XyTracker_FilterQualityUpdate"]();
    end
end

-- 初始化品质筛选UI元素
_G["InitializeQualityCheckboxes"] = function(showDebug)
    if showDebug then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 开始初始化品质筛选UI元素...", 0.5, 1, 0.5);
    end
    
    -- 初始化配置
    InitConfig();
    
    -- 获取主框架
    local mainFrame = GetOrCreateMainFrame();
    if not mainFrame then
        return;
    end
    
    -- 获取筛选框架
    local filterFrame = GetOrCreateFilterFrame(mainFrame);
    
    -- 创建或更新UI元素
    CreateOrUpdateQualityUI(filterFrame, false, showDebug);
    
    if showDebug then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker] 品质筛选UI元素初始化完成！", 0.5, 1, 0.5);
    end
end

-- 强制创建所有品质筛选UI元素
_G["ForceCreateQualityFilterUI"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 开始强制创建品质筛选UI元素...", 0.5, 1, 0.5);
    
    -- 初始化配置
    InitConfig();
    
    -- 获取主框架
    local mainFrame = GetOrCreateMainFrame();
    if not mainFrame then
        return;
    end
    
    -- 获取筛选框架
    local filterFrame = GetOrCreateFilterFrame(mainFrame);
    
    -- 强制创建UI元素
    CreateOrUpdateQualityUI(filterFrame, true, true);
    
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 强制创建品质筛选UI元素完成！", 0.5, 1, 0.5);
end

-- 更新品质筛选状态
_G["XyTracker_FilterQualityUpdate"] = function()
    -- 获取复选框状态
    local orangeEnabled = getglobal("OrangeQualityCheck") and getglobal("OrangeQualityCheck"):GetChecked() or false;
    local purpleEnabled = getglobal("PurpleQualityCheck") and getglobal("PurpleQualityCheck"):GetChecked() or false;
    local blueEnabled = getglobal("BlueQualityCheck") and getglobal("BlueQualityCheck"):GetChecked() or false;
    local greenEnabled = getglobal("GreenQualityCheck") and getglobal("GreenQualityCheck"):GetChecked() or false;
    local whiteEnabled = getglobal("WhiteQualityCheck") and getglobal("WhiteQualityCheck"):GetChecked() or false;
    
    -- 更新筛选选项
    XyTrackerOptions.QualityFilters[5] = orangeEnabled;
    XyTrackerOptions.QualityFilters[4] = purpleEnabled;
    XyTrackerOptions.QualityFilters[3] = blueEnabled;
    XyTrackerOptions.QualityFilters[2] = greenEnabled;
    XyTrackerOptions.QualityFilters[1] = whiteEnabled;
    XyTrackerOptions.QualityFilters[0] = whiteEnabled;  -- 白色包含灰色
    
    -- 应用筛选并更新列表
    ApplyQualityFilter();
    if _G["XyTracker_UpdateLootList"] then
        _G["XyTracker_UpdateLootList"]();
    end
end

-- 创建一个全局变量来存储原始筛选后的列表
OriginalFilteredLootList = OriginalFilteredLootList or {};

-- 应用品质筛选
_G["ApplyQualityFilter"] = function()
    -- 确保LootList存在
    if not LootList then
        LootList = {};
    end
    
    -- 清空原始筛选列表
    OriginalFilteredLootList = {};
    
    -- 根据物品品质进行筛选，创建临时数据库表
    local i, lootItem, itemQuality;
    for i = 1, table.getn(LootList) do
        lootItem = LootList[i];
        -- 只处理有效的物品
        if lootItem and type(lootItem) == "table" and lootItem.itemLink and type(lootItem.itemLink) == "string" then
            -- 在1.12版本中通过解析物品链接中的颜色代码来确定品质
            local itemColor = string.match(lootItem.itemLink, "|c(%x+)|H");
            if itemColor then
                -- 根据颜色代码近似判断品质，只添加符合筛选条件的物品
                if (itemColor == "ffff8000" and XyTrackerOptions.QualityFilters[5]) or -- 橙色
                    (itemColor == "ffa335ee" and XyTrackerOptions.QualityFilters[4]) or -- 紫色
                    (itemColor == "ff0070dd" and XyTrackerOptions.QualityFilters[3]) or -- 蓝色
                    (itemColor == "ff1eff00" and XyTrackerOptions.QualityFilters[2]) or -- 绿色
                    ((itemColor == "ffffffff" or itemColor == "ff9d9d9d") and XyTrackerOptions.QualityFilters[1]) then -- 白色/灰色
                    table.insert(OriginalFilteredLootList, lootItem);
                end
            end
            -- 注意：不再默认显示无法判断品质的物品
        end
        -- 注意：不再默认显示无效物品
    end
end

-- 重置XyTracker UI元素
local function ResetXyTrackerUI()
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 开始重置品质筛选UI元素...", 0.5, 1, 0.5);
    
    -- 删除已有的UI元素以便重新创建
    local qualities = {"Orange", "Purple", "Blue", "Green", "White"};
    for _, quality in ipairs(qualities) do
        local checkBox = getglobal(quality .. "QualityCheck");
        local textLabel = getglobal(quality .. "QualityText");
        if checkBox then
            checkBox:Hide();
            checkBox = nil;
        end
        if textLabel then
            textLabel:Hide();
            textLabel = nil;
        end
    end
    
    -- 删除筛选框架
    local filterFrame = getglobal("XyTrackerQualityFilterFrame");
    if filterFrame then
        filterFrame:Hide();
        filterFrame = nil;
    end
    
    -- 重置配置
 InitializeXyTrackerOptions()
    
    -- 延迟一小段时间后重新初始化，确保UI元素已完全清理
    local resetTimerFrame = CreateFrame("Frame");
    local resetTime = GetTime() + 0.1; -- 0.1秒后执行
    
    resetTimerFrame:SetScript("OnUpdate", function()
        if GetTime() >= resetTime then
            -- 清除定时器，避免重复执行
            resetTimerFrame:SetScript("OnUpdate", nil);
            
            -- 重新初始化复选框
            if _G["InitializeQualityCheckboxes"] and type(_G["InitializeQualityCheckboxes"]) == "function" then
                _G["InitializeQualityCheckboxes"]();
                DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 已调用 InitializeQualityCheckboxes() 函数。", 0.5, 1, 0.5);
            else
                DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 警告: InitializeQualityCheckboxes 函数未找到!", 1, 0, 0);
            end
            
            -- 触发列表更新
            if _G["XyTracker_FilterQualityUpdate"] and type(_G["XyTracker_FilterQualityUpdate"]) == "function" then
                _G["XyTracker_FilterQualityUpdate"]();
                DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 已调用 XyTracker_FilterQualityUpdate() 函数。", 0.5, 1, 0.5);
            else
                DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 警告: XyTracker_FilterQualityUpdate 函数未找到!", 1, 0, 0);
            end
            
            -- 显示完成信息
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 品质筛选UI重置完成！请打开XyTracker窗口查看效果。", 0.5, 1, 0.5);
            DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 如果仍有问题，请尝试重载界面 (/reload) 后再次使用此命令。", 0.5, 1, 0.5);
        end
    end);
end

-- 测试XyTracker UI元素状态
local function TestXyTrackerUI()
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 正在测试UI元素状态...", 0.5, 1, 0.5);
    
    -- 检查主框架
    local mainFrame = getglobal("XyTrackerLootListFrame");
    DEFAULT_CHAT_FRAME:AddMessage("[主框架]:", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerLootListFrame: " .. (mainFrame and (mainFrame:IsVisible() and "存在且可见" or "存在但隐藏") or "未找到"), 0.5, 1, 0.5);
    
    -- 检查品质筛选UI元素
    DEFAULT_CHAT_FRAME:AddMessage("[品质筛选元素]:", 0.5, 1, 0.5);
    
    local qualities = {
        {name = "Orange", color = {r = 1, g = 0.5, b = 0}, label = "橙", index = 5},
        {name = "Purple", color = {r = 0.8, g = 0.3, b = 0.9}, label = "紫", index = 4},
        {name = "Blue", color = {r = 0, g = 0.5, b = 1}, label = "蓝", index = 3},
        {name = "Green", color = {r = 0, g = 1, b = 0}, label = "绿", index = 2},
        {name = "White", color = {r = 1, g = 1, b = 1}, label = "白", index = 1}
    };
    
    local allFound = true;
    
    for _, quality in ipairs(qualities) do
        local checkBoxName = quality.name .. "QualityCheck";
        local textName = quality.name .. "QualityText";
        local checkBox = getglobal(checkBoxName);
        local textLabel = getglobal(textName);
        
        if checkBox and textLabel then
            DEFAULT_CHAT_FRAME:AddMessage("  " .. quality.label .. "品质: 复选框和文本标签均存在", 0.5, 1, 0.5);
        else
            allFound = false;
            DEFAULT_CHAT_FRAME:AddMessage("  " .. quality.label .. "品质: " .. (checkBox and "复选框存在" or "复选框缺失") .. ", " .. (textLabel and "文本标签存在" or "文本标签缺失"), 1, 0.5, 0);
        end
    end
    
    -- 检查配置
    DEFAULT_CHAT_FRAME:AddMessage("[配置状态]:", 0.5, 1, 0.5);
    if XyTrackerOptions and XyTrackerOptions.QualityFilters then
        DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerOptions.QualityFilters 存在", 0.5, 1, 0.5);
        for _, quality in ipairs(qualities) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. quality.label .. "品质显示: " .. (XyTrackerOptions.QualityFilters[quality.index] and "是" or "否"), 0.5, 1, 0.5);
        end
    else
        allFound = false;
        DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerOptions.QualityFilters 未找到", 1, 0, 0);
    end
    
    -- 显示测试结果
    if allFound then
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 测试完成：所有UI元素状态正常！", 0.5, 1, 0.5);
    else
        DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 测试完成：发现缺失的UI元素！建议使用 /xyfixui reset 命令修复。", 1, 0, 0);
    end
end

-- 显示帮助信息
local function ShowXyFixUIHelp()
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 使用说明:", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("/xyfixui reset - 重置并重新创建所有品质筛选UI元素", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("/xyfixui forcecreate - 强制创建所有缺失的UI元素（无需重置现有元素）", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("/xyfixui test - 测试品质筛选UI元素状态", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("  重置或强制创建后请确保打开XyTracker窗口查看效果。", 0.5, 1, 0.5);
end

-- 添加调试函数以验证全局函数是否正确定义
_G["XyTracker_FilterDebug"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker Filter Debug - Manual]", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("XyTracker_FilterQualityUpdate exists in _G: " .. (XyTracker_FilterQualityUpdate and "YES" or "NO"), 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("ApplyQualityFilter exists in _G: " .. (ApplyQualityFilter and "YES" or "NO"), 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("InitializeQualityCheckboxes exists in _G: " .. (InitializeQualityCheckboxes and "YES" or "NO"), 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("XyTracker_UpdateLootList exists in _G: " .. (XyTracker_UpdateLootList and "YES" or "NO"), 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage(" ");
    
    -- 检查主框架和筛选框架
    local mainFrame = getglobal("XyTrackerLootListFrame");
    local filterFrame = getglobal("XyTrackerQualityFilterFrame");
    DEFAULT_CHAT_FRAME:AddMessage("[框架状态]: ", 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerLootListFrame: " .. (mainFrame and "存在" or "未找到"), 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerQualityFilterFrame: " .. (filterFrame and (filterFrame:IsVisible() and "存在且可见" or "存在但隐藏") or "未找到"), 0.5, 1, 0.5);
    DEFAULT_CHAT_FRAME:AddMessage(" ");
    
    -- 检查选项配置
    DEFAULT_CHAT_FRAME:AddMessage("[配置状态]: ", 0.5, 1, 0.5);
    if XyTrackerOptions and XyTrackerOptions.QualityFilters then
        DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerOptions.QualityFilters 存在");
        DEFAULT_CHAT_FRAME:AddMessage("  橙色品质显示: " .. (XyTrackerOptions.QualityFilters[5] and "是" or "否"));
        DEFAULT_CHAT_FRAME:AddMessage("  紫色品质显示: " .. (XyTrackerOptions.QualityFilters[4] and "是" or "否"));
        DEFAULT_CHAT_FRAME:AddMessage("  蓝色品质显示: " .. (XyTrackerOptions.QualityFilters[3] and "是" or "否"));
        DEFAULT_CHAT_FRAME:AddMessage("  绿色品质显示: " .. (XyTrackerOptions.QualityFilters[2] and "是" or "否"));
        DEFAULT_CHAT_FRAME:AddMessage("  白色品质显示: " .. (XyTrackerOptions.QualityFilters[1] and "是" or "否"));
    else
        DEFAULT_CHAT_FRAME:AddMessage("  XyTrackerOptions.QualityFilters 未找到");
    end
    DEFAULT_CHAT_FRAME:AddMessage(" ");
    
    -- 检查复选框状态
    DEFAULT_CHAT_FRAME:AddMessage("[复选框状态检查]: ", 0.5, 1, 0.5);
    
    local qualities = {
        {name = "Orange", color = {r = 1, g = 0.5, b = 0}, label = "橙"},
        {name = "Purple", color = {r = 0.8, g = 0.3, b = 0.9}, label = "紫"},
        {name = "Blue", color = {r = 0, g = 0.5, b = 1}, label = "蓝"},
        {name = "Green", color = {r = 0, g = 1, b = 0}, label = "绿"},
        {name = "White", color = {r = 1, g = 1, b = 1}, label = "白"}
    };
    
    for _, quality in ipairs(qualities) do
        local checkBoxName = quality.name .. "QualityCheck";
        local checkBox = getglobal(checkBoxName);
        
        if checkBox then
            local isVisible = checkBox:IsVisible();
            local isChecked = checkBox:GetChecked();
            local x, y = checkBox:GetLeft(), checkBox:GetTop();
            
            DEFAULT_CHAT_FRAME:AddMessage("  " .. checkBoxName .. ": " .. (isVisible and "可见" or "隐藏") .. ", " .. (isChecked and "已勾选" or "未勾选") .. ", 位置: x=" .. (x and string.format("%.2f", x) or "nil") .. ", y=" .. (y and string.format("%.2f", y) or "nil"), 0.5, 1, 0.5);
        else
            DEFAULT_CHAT_FRAME:AddMessage("  " .. checkBoxName .. ": 未找到", 0.5, 1, 0.5);
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ");
    DEFAULT_CHAT_FRAME:AddMessage("[文本标签状态检查]: ", 0.5, 1, 0.5);
    
    for _, quality in ipairs(qualities) do
        local textName = quality.name .. "QualityText";
        local textLabel = getglobal(textName);
        
        if textLabel then
            local isVisible = textLabel:IsVisible();
            local text = textLabel:GetText();
            local x, y = textLabel:GetLeft(), textLabel:GetTop();
            
            DEFAULT_CHAT_FRAME:AddMessage("  " .. textName .. ": " .. (isVisible and "可见" or "隐藏") .. ", 文本: '" .. (text or "nil") .. "', 位置: x=" .. (x and string.format("%.2f", x) or "nil") .. ", y=" .. (y and string.format("%.2f", y) or "nil"), 0.5, 1, 0.5);
        else
            DEFAULT_CHAT_FRAME:AddMessage("  " .. textName .. ": 未找到", 0.5, 1, 0.5);
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ");
    DEFAULT_CHAT_FRAME:AddMessage("使用 /xydbg reset 命令可以重置UI元素并重新创建复选框和文本标签。", 0.5, 1, 0.5);
end

-- 注册斜杠命令
SLASH_XYFIXUI1 = "/xyfixui";

-- 主函数处理斜杠命令
function SlashCmdList.XYFIXUI(cmd)
    local cmd = string.lower(cmd);
    
    if cmd == "reset" then
        ResetXyTrackerUI();
    elseif cmd == "test" then
        TestXyTrackerUI();
    elseif cmd == "forcecreate" then
        ForceCreateQualityFilterUI();
    else
        ShowXyFixUIHelp();
    end
end

-- 添加斜杠命令以手动运行调试
SLASH_XYDBG1 = "/xydbg";
function SlashCmdList.XYDBG(msg)
    if msg == "reset" then
        -- 删除已有的UI元素以便重新创建
        local qualities = {"Orange", "Purple", "Blue", "Green", "White"};
        for _, quality in ipairs(qualities) do
            local checkBox = getglobal(quality .. "QualityCheck");
            local textLabel = getglobal(quality .. "QualityText");
            if checkBox then
                checkBox:Hide();
                checkBox = nil;
            end
            if textLabel then
                textLabel:Hide();
                textLabel = nil;
            end
        end
        
        -- 删除筛选框架
        local filterFrame = getglobal("XyTrackerQualityFilterFrame");
        if filterFrame then
            filterFrame:Hide();
            filterFrame = nil;
        end
        
        -- 重置配置
        InitializeXyTrackerOptions()
        
        -- 延迟一小段时间后重新初始化，确保UI元素已完全清理
        local resetTimerFrame = CreateFrame("Frame");
        local resetTime = GetTime() + 0.1; -- 0.1秒后执行
        
        resetTimerFrame:SetScript("OnUpdate", function()
            if GetTime() >= resetTime then
                -- 清除定时器，避免重复执行
                resetTimerFrame:SetScript("OnUpdate", nil);
                
                -- 重新初始化复选框
                if _G["InitializeQualityCheckboxes"] then
                    _G["InitializeQualityCheckboxes"]();
                end
                
                -- 触发列表更新
                if _G["XyTracker_FilterQualityUpdate"] then
                    _G["XyTracker_FilterQualityUpdate"]();
                end
            end
        end);
    else
        -- 显示调试信息
        XyTracker_FilterDebug();
    end
end

-- 加载时显示欢迎信息
local function XyTracker_FixUI_OnLoad()
    DEFAULT_CHAT_FRAME:AddMessage("[XyTracker FixUI] 已加载! 输入 /xyfixui 获取帮助。", 0.5, 1, 0.5);
end

-- 创建加载框架并注册事件
local fixUIFrame = CreateFrame("Frame");
fixUIFrame:RegisterEvent("ADDON_LOADED");
fixUIFrame:SetScript("OnEvent", function()
    local addonName = arg1; -- 1.12中event是全局变量，arg1才是插件名
    if event == "ADDON_LOADED" and addonName == "XyTracker" then
        XyTracker_FixUI_OnLoad();
    end
end);

-- 全局变量，用于存储筛选后的物品列表
FilteredLootList = {};

-- 插件加载时的初始化函数，确保在全局作用域中定义
_G["XyTracker_Filter_OnLoad"] = function()
    -- 检查并创建必要的变量
    if not FilteredLootList then
        FilteredLootList = {};
    end
    
    InitializeXyTrackerOptions()
    
    -- 立即初始化品质筛选UI元素
    if _G["InitializeQualityCheckboxes"] and type(_G["InitializeQualityCheckboxes"]) == "function" then
        _G["InitializeQualityCheckboxes"]();
    end
    
    -- 注册必要的事件
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
end

-- 事件处理函数 - 完全兼容WoW 1.12版本API和Lua 5.0
-- 注意：XML中调用方式为XyTracker_Filter_OnEvent(event)，同时
-- 在WoW 1.12中，事件参数也通过全局变量"event", "arg1", "arg2"等传递
_G["XyTracker_Filter_OnEvent"] = function(eventName)
    -- 同时兼容XML传递的参数和全局变量方式
    local event = eventName or event or arg1;
    
    -- 对于ADDON_LOADED事件，arg1是插件名称
    local addonName = arg1;
    
    if event == "ADDON_LOADED" and addonName == "XyTracker" then
        -- 确保XyTrackerOptions存在并初始化品质筛选配置
        InitializeXyTrackerOptions()
    elseif event == "VARIABLES_LOADED" then
        -- 变量加载完成时初始化筛选功能
        if not FilteredLootList then
            FilteredLootList = {};
        end
        
        InitializeXyTrackerOptions()
        
        -- 初始化复选框状态
        if _G["InitializeQualityCheckboxes"] and type(_G["InitializeQualityCheckboxes"]) == "function" then
            _G["InitializeQualityCheckboxes"]();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 玩家进入世界时应用筛选
        ApplyQualityFilter();
        -- 初始化复选框状态
        if _G["InitializeQualityCheckboxes"] and type(_G["InitializeQualityCheckboxes"]) == "function" then
            _G["InitializeQualityCheckboxes"]();
        end
    end
    
    -- 在任何事件触发时，确保UI元素是最新的（特别是当主窗口显示时）
    if _G["XyTrackerLootListFrame"] and _G["XyTrackerLootListFrame"]:IsVisible() then
        if _G["InitializeQualityCheckboxes"] and type(_G["InitializeQualityCheckboxes"]) == "function" then
            _G["InitializeQualityCheckboxes"]();
        end
        if _G["XyTracker_FilterQualityUpdate"] and type(_G["XyTracker_FilterQualityUpdate"]) == "function" then
            _G["XyTracker_FilterQualityUpdate"]();
        end
    end
end

-- 重写原有的XyTracker_UpdateLootList函数以支持筛选，确保在全局作用域中定义
-- 幂等守卫：本文件可能被加载两次，重复包装会让originalUpdateLootList捕获到已覆写的函数，导致无限递归
if _G["XyTracker_UpdateLootList_Overridden"] then
    return;
end
_G["XyTracker_UpdateLootList_Overridden"] = true;
local originalUpdateLootList = _G["XyTracker_UpdateLootList"];
_G["XyTracker_UpdateLootList"] = function()
    -- 确保LootList、OriginalFilteredLootList和FilteredLootList存在
    if not LootList then
        LootList = {};
    end
    if not OriginalFilteredLootList then
        OriginalFilteredLootList = {};
    end
    
    -- 每次都重新应用筛选，确保使用最新的筛选条件
    if table.getn(LootList) > 0 then
        ApplyQualityFilter();
    end
    
    -- 创建临时表FilteredLootList，仅包含OriginalFilteredLootList中的物品
    -- 这样确保排序时使用的是严格按照筛选条件创建的数据，不会混入被筛选掉的物品
    FilteredLootList = {};
    for i = 1, table.getn(OriginalFilteredLootList) do
        FilteredLootList[i] = OriginalFilteredLootList[i];
    end
    
    -- 对筛选列表进行排序
    XyLootSortListFiltered();
    
    local scrollFrame = getglobal("LootListScrollFrame");
    local numItems = table.getn(FilteredLootList);
    
    FauxScrollFrame_Update(scrollFrame, numItems, 16, 25);
    
    -- 首先隐藏所有按钮，确保没有旧数据残留
    for i = 1, 16 do
        local button = getglobal("LootFrameListButton"..i);
        if button then
            button:Hide();
        end
    end
    
    -- 然后只显示需要的按钮并设置数据
    for i = 1, 16 do
        local button = getglobal("LootFrameListButton"..i);
        local index = i + FauxScrollFrame_GetOffset(scrollFrame);
        
        if index <= numItems and button then
            local lootItem = FilteredLootList[index];
            
            -- 加强数据验证，确保lootItem是有效表
            if not lootItem or type(lootItem) ~= "table" then
                button:Hide();
            else
                -- 设置按钮可见
                button:Show();
                
                -- 设置物品名称并根据品质染色
                local nameText = getglobal(button:GetName().."Name");
                if nameText then
                    local safeItemName = lootItem.itemName and tostring(lootItem.itemName) or "未知物品";
                    local safeItemLink = lootItem.itemLink and tostring(lootItem.itemLink) or "";
                    
                    -- 安全地从物品链接中提取颜色代码
                    local itemColor = nil;
                    if safeItemLink and safeItemLink ~= "" then
                        local success, _, _, color = pcall(string.find, safeItemLink, "|c(%x+)|H");
                        if success and color then
                            itemColor = color;
                        end
                    end
                    
                    -- 应用颜色或使用默认颜色
                    if itemColor then
                        -- 确保颜色代码格式正确
                        if string.len(itemColor) == 8 then
                            nameText:SetText("|c"..itemColor..safeItemName.."|r");
                        else
                            nameText:SetText(safeItemName);
                        end
                    else
                        nameText:SetText(safeItemName);
                    end
                    nameText:SetWidth(100);  -- 缩短物品名称宽度
                end
                
                -- 设置拾取时间
                local timeText = getglobal(button:GetName().."Time");
                if timeText then
                    local safeTimestamp = lootItem.timestamp; -- 数字和表格式时间戳都直接传递，Xy_FormatTime 会处理
                    local timeString = Xy_FormatTime(safeTimestamp);
                    timeText:SetText(timeString);
                    timeText:SetWidth(80);
                end
                
                -- 设置归属玩家
                local playerText = getglobal(button:GetName().."Xy");
                if playerText then
                    local safePlayerName = lootItem.playerName and tostring(lootItem.playerName) or "未知玩家";
                    playerText:SetText(safePlayerName);
                    playerText:SetWidth(80);
                end
                
                -- 设置使用分数 - 修复分数显示问题
                local pointsText = getglobal(button:GetName().."DKP");
                if pointsText then
                    -- 尝试从多个可能的字段获取分数值
                    local points = lootItem.points or lootItem.score or 0;
                    
                    -- 如果分数字段存在但值为空，使用0
                    if points == nil or points == "" then
                        points = 0;
                    end
                    
                    -- 确保是数字类型
                    if type(points) ~= "number" then
                        points = tonumber(points) or 0;
                    end
                    
                    pointsText:SetText(tostring(points));
                    pointsText:SetWidth(50);
                    pointsText:Show(); -- 强制显示
                end
                
                -- 设置是否许愿 - 修复许愿状态显示问题
                local isWishText = getglobal(button:GetName().."IsWish");
                if isWishText then
                    -- 尝试从多个可能的字段获取许愿状态
                    local isWish = lootItem.isWish or lootItem.wish or false;
                    
                    -- 处理字符串类型的是/否值
                    if type(isWish) == "string" then
                        isWish = (string.lower(isWish) == "yes" or string.lower(isWish) == "是");
                    end
                    
                    -- 许愿成功，显示不同颜色和文字
                    if isWish then
                        isWishText:SetText("已许愿");
                        isWishText:SetTextColor(1, 0.5, 0, 1);  -- 橙色，代表许愿成功
                    else
                        isWishText:SetText("否");
                        isWishText:SetTextColor(1, 1, 1, 1);  -- 白色
                    end
                    isWishText:SetWidth(60);
                    isWishText:Show(); -- 强制显示
                end
                
                -- 确保所有文本框都可见
                if button then
                    button:Show();
                end
            end
        end
    end
    
    -- 强制刷新滚动框架，确保显示最新状态
    FauxScrollFrame_Update(scrollFrame, numItems, 16, 25);
end

-- 添加筛选列表的排序功能，确保在全局作用域中定义
_G["XyLootSortListFiltered"] = function()
    -- 确保FilteredLootList存在且为表类型
    if not FilteredLootList or type(FilteredLootList) ~= "table" then
        return;
    end
    
    local numItems = table.getn(FilteredLootList);
    
    -- 执行排序前先清理无效条目
    local validItems = {}
    for i = 1, numItems do
        local item = FilteredLootList[i]
        if item and type(item) == "table" then
            table.insert(validItems, item)
        end
    end
    
    -- 如果有效条目不足2个，无需排序
    if table.getn(validItems) < 2 then
        -- 但仍需更新FilteredLootList以移除无效条目
        FilteredLootList = validItems
        return
    end
    
    -- 确保排序变量已初始化
    if not LootSortField then
        LootSortField = "timestamp";
    end
    if not LootSortOrder then
        LootSortOrder = 1;
    end
    
    -- 从物品链接中提取物品ID的辅助函数
    local function ExtractItemID(itemLink)
        if not itemLink or type(itemLink) ~= "string" then
            return "0"  -- 返回默认值而不是空字符串
        end
        
        -- 尝试从物品链接中提取物品ID
        local itemID = string.match(itemLink, "|Hitem:(%d+)")
        return itemID or "0"  -- 确保总是返回一个有效的字符串
    end
    
    -- 从物品链接中提取物品品质的辅助函数
    local function GetItemQualityFromLink(itemLink)
        if not itemLink or type(itemLink) ~= "string" then
            return 0  -- 默认返回最低品质
        end
        
        -- 尝试从物品链接中提取颜色代码
        local itemColor = string.match(itemLink, "|c(%x+)|H")
        if not itemColor then
            return 0
        end
        
        -- 根据颜色代码确定物品品质
        if itemColor == "ffff8000" then  -- 橙色
            return 5
        elseif itemColor == "ffa335ee" then  -- 紫色
            return 4
        elseif itemColor == "ff0070dd" then  -- 蓝色
            return 3
        elseif itemColor == "ff1eff00" then  -- 绿色
            return 2
        elseif itemColor == "ffffffff" then  -- 白色
            return 1
        elseif itemColor == "ff9d9d9d" then  -- 灰色
            return 0
        else
            return 0
        end
    end
    
    -- 排序逻辑
    local sortFunc = function(a, b)
        -- 安全检查：确保a和b是有效的表
        if not a or type(a) ~= "table" then
            return false
        end
        if not b or type(b) ~= "table" then
            return true
        end
        
        -- 特殊处理物品名称排序：先按品质，再按ID
        if LootSortField == "itemName" then
            -- 获取物品品质
            local qualityA = GetItemQualityFromLink(a.itemLink or "")
            local qualityB = GetItemQualityFromLink(b.itemLink or "")
            
            -- 先按品质排序（高品质在前）
            if qualityA ~= qualityB then
                return qualityA * LootSortOrder > qualityB * LootSortOrder
            else
                -- 品质相同时，按物品ID排序
                local itemIDA = tonumber(ExtractItemID(a.itemLink or "")) or 0
                local itemIDB = tonumber(ExtractItemID(b.itemLink or "")) or 0
                return itemIDA * LootSortOrder < itemIDB * LootSortOrder
            end
        else
            -- 其他字段的排序逻辑
            local valA = a[LootSortField]
            local valB = b[LootSortField]
            
            if valA == valB then
                return (a.itemName or "") < (b.itemName or "")
            else
                if LootSortField == "timestamp" then
                    -- 时间戳排序：按照时钟*100+分钟排列
                    local function getTimeValue(timeVal)
                        if not timeVal then return 0 end
                        if type(timeVal) == "table" then
                            -- 处理表类型的时间戳
                            if timeVal.hour and timeVal.minute then
                                return timeVal.hour * 100 + timeVal.minute
                            elseif timeVal.timestamp then
                                -- 支持嵌套的timestamp字段
                                return getTimeValue(timeVal.timestamp)
                            end
                        elseif type(timeVal) == "string" then
                            -- 增强字符串格式处理
                            local h, m = string.match(timeVal, "(%d+):(%d+)")
                            if h and m then return tonumber(h)*100 + tonumber(m) end
                            -- 尝试其他可能的时间格式
                            h, m = string.match(timeVal, "(%d+)%s*:%s*(%d+)")
                            if h and m then return tonumber(h)*100 + tonumber(m) end
                        end
                        return 0
                    end
                    return getTimeValue(valA) * LootSortOrder < getTimeValue(valB) * LootSortOrder
                elseif LootSortField == "isWish" then
                    -- 是否许愿排序
                    local wishA = valA and 1 or 0
                    local wishB = valB and 1 or 0
                    return wishA * LootSortOrder > wishB * LootSortOrder
                elseif type(valA) == "number" and type(valB) == "number" then
                    -- 数字排序
                    return valA * LootSortOrder < valB * LootSortOrder
                else
                    -- 字符串排序（用于归属玩家按名字顺序排列）
                    return tostring(valA or "") < tostring(valB or "")
                end
            end
        end
    end
    
    -- 执行排序
    table.sort(validItems, sortFunc)
    
    -- 更新FilteredLootList
    FilteredLootList = validItems;
end