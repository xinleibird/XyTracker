-- XyTracker pfUI 皮肤支持
-- 当 pfUI 存在时，为 XyTracker 的各窗口应用 pfUI 风格
-- 全部改动仅作用于外观，不触碰任何现有逻辑

local noop = function() end
local layoutApplied = false

local function ApplySkin()
    if not pfUI or type(pfUI.GetEnvironment) ~= "function" then return false end
    local penv = pfUI:GetEnvironment()
    if not penv then return false end

    local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinCheckbox,
        SkinDropDown, SkinScrollbar =
        penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton,
        penv.SkinCheckbox, penv.SkinDropDown, penv.SkinScrollbar

    -- =======================
    -- 辅助：Skin 标准按钮 (UIPanelButtonTemplate/OptionsButtonTemplate)
    -- =======================
    local function SkinPanelButton(btn)
        if not btn or btn.pfUISkinned then return end
        btn.pfUISkinned = true

        StripTextures(btn)
        if btn.Left then
            btn.Left:SetTexture("")
            btn.Left.SetTexture = noop
        end
        if btn.Middle then
            btn.Middle:SetTexture("")
            btn.Middle.SetTexture = noop
        end
        if btn.Right then
            btn.Right:SetTexture("")
            btn.Right.SetTexture = noop
        end
        SkinButton(btn)
    end

    -- 辅助：Skin 输入框
    local function SkinEditBox(eb)
        if not eb or eb.pfUISkinned then return end
        eb.pfUISkinned = true
        StripTextures(eb, true, "BACKGROUND")
        CreateBackdrop(eb, nil, true)
    end

    -- 辅助：Skin 列表表头（XyColumnHeaderTemplate，去掉 WhoFrame-ColumnTabs 纹理只留文字）
    local function SkinColumnHeader(btn)
        if not btn or btn.pfUISkinned then return end
        btn.pfUISkinned = true
        StripTextures(btn)
    end

    -- 辅助：Skin 窗口（去 XML 原生 Backdrop 后换 pfUI 背景）
    local function SkinWindow(frame)
        if not frame or frame.pfUISkinned then return false end
        frame.pfUISkinned = true
        frame:SetBackdrop(nil)
        StripTextures(frame)
        CreateBackdrop(frame, nil, nil, .75)
        return true
    end

    -- =======================
    -- 主窗口 (XyTrackerFrame)
    -- =======================
    local mainFrame = _G["XyTrackerFrame"]
    if SkinWindow(mainFrame) then
        -- 关闭按钮
        SkinCloseButton(_G["XyTrackerFrameCloseButton"], mainFrame.backdrop, -6, -6)

        -- 所有 UIPanelButtonTemplate 按钮（XML 里是 $parentXxx，全局名 XyTrackerFrameXxx）
        local buttonNames = {
            "XyTrackerFrameStartButton",          -- 开始
            "XyTrackerFrameStopButton",           -- 停止
            "XyTrackerFrameResetButton",          -- 重置
            "XyTrackerFrameRefreshButton",        -- 刷新
            "XyTrackerFrameChuShiHua_DKP",        -- 初始化DKP
            "XyTrackerFrameSaveWishButton",       -- 保存许愿
            "XyTrackerFrameRestoreWishButton",    -- 恢复许愿
            "XyTrackerFrameLootListButton",       -- 拾取列表
            "XyTrackerFrameBlacklistButton",      -- 黑名单
            "XyTrackerFrameBroadcastButton",      -- 播报许愿
            "XyTrackerFrameAnnounceButton",       -- 未许愿人数
            "XyTrackerFrameExportButton",         -- 导出许愿
            "XyTrackerFrameEditStarttextButton",  -- 开团公告
            "XyTrackerFrameRelinquishButton",     -- 放弃权限
            "XyTrackerFrameDeclarationButton",    -- 宣言
            "XyTrackerFrameAnnounceDeclarationButton", -- 通告宣言
        }
        for _, name in ipairs(buttonNames) do
            SkinPanelButton(_G[name])
        end

        -- 七个模式/功能复选框（XML 为 virtual 模板，本客户端若未实例化则判空跳过）
        local checkNames = {
            "autoModeButtons", "autoAnnounceButton", "autoMinButtons",
            "greenModeButtons", "blueModeButtons", "purpleModeButtons",
            "autoBackupButton",
        }
        for _, name in ipairs(checkNames) do
            local check = _G[name]
            if check and not check.pfUISkinned then
                check.pfUISkinned = true
                SkinCheckbox(check, 20)
            end
        end

        -- 许愿列表行内 +/- 与"完"按钮（XyFrameListButton1..N，XML 静态创建）
        for i = 1, 40 do
            local rowFrame = _G["XyFrameListButton" .. i]
            if not rowFrame then break end

            for j = 1, 2 do
                local suffix = j == 1 and "AddDkp" or "MinusDkp"
                local txt = j == 1 and "+" or "-"
                local b = _G["XyFrameListButton" .. i .. suffix]
                if b and not b.pfUISkinned then
                    b.pfUISkinned = true
                    b:SetNormalTexture("")
                    b:SetPushedTexture("")
                    b:SetDisabledTexture("")
                    b:SetHighlightTexture("")
                    SkinButton(b)
                    -- 纯纹理按钮没有文字层，补一个字符标签
                    if not b.text then
                        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
                    end
                    b.text:SetText(txt)
                end
            end

            local complete = _G["XyFrameListButton" .. i .. "CompleteWish"]
            if complete and not complete.pfUISkinned then
                complete.pfUISkinned = true
                complete:SetHighlightTexture("")
                SkinButton(complete)  -- 保留其"完"文字（FontString 已在 XML 中定义）
            end
        end

        -- 许愿列表表头（角色名/职业/许愿/分数/操作）
        for i = 1, 5 do
            SkinColumnHeader(_G["XyFrameColumnHeader" .. i])
        end

        -- 许愿列表滚动条（FauxScrollFrameTemplate 子框架，名 <滚动框架名>ScrollBar）
        local scrollBar = _G["XyListScrollFrameScrollBar"]
        if scrollBar then
            SkinScrollbar(scrollBar)

            -- >>> shiftX 就是左右移动滚动条的参数：调大右移，调小左移，0 = 原位 <<<
            if not scrollBar.xyShifted then
                scrollBar.xyShifted = true
                local shiftX = 0
                local pts = {}
                for i = 1, scrollBar:GetNumPoints() do
                    local p, rel, rp, x, y = scrollBar:GetPoint(i)
                    table.insert(pts, { p = p, rel = rel, rp = rp, x = x, y = y })
                end
                scrollBar:ClearAllPoints()
                if table.getn(pts) > 0 then
                    for _, pt in ipairs(pts) do
                        scrollBar:SetPoint(pt.p, pt.rel, pt.rp, pt.x + shiftX, pt.y)
                    end
                else
                    -- 兜底：按 FauxScrollFrameTemplate 的默认锚点重建
                    scrollBar:SetPoint("TOPRIGHT", scrollBar:GetParent(), "TOPRIGHT", shiftX, -16)
                    scrollBar:SetPoint("BOTTOMRIGHT", scrollBar:GetParent(), "BOTTOMRIGHT", shiftX, 16)
                end
            end
        end
    end   -- <-- 主窗口处理结束

    -- ===== 新增：调整布局以解决按钮与标题重叠 =====
    if not layoutApplied and mainFrame then
        -- 下移并左移停止按钮（单独调整）
        local topRowButtons = {
            "XyTrackerFrameStopButton",
        }
        local offsetY = -15   -- 下移 15 像素，可根据需要调整
        local offsetX = 3   -- 向左偏移 10 像素（负值左移），可根据需要调整
        -- 获取停止按钮的原始 Y 偏移作为基准
        local stopBtn = _G["XyTrackerFrameStopButton"]
        local baseY = 0
        if stopBtn then
            local _, _, _, _, yOff = stopBtn:GetPoint(1)
            if yOff then baseY = yOff end
        end
        -- 统一设置所有按钮的 Y 偏移为 baseY + offsetY，X 偏移增加 offsetX
        for _, name in ipairs(topRowButtons) do
            local btn = _G[name]
            if btn then
                local point, relative, relPoint, xOff, _ = btn:GetPoint(1)
                if point then
                    btn:ClearAllPoints()
                    btn:SetPoint(point, relative, relPoint, xOff + offsetX, baseY + offsetY)
                end
            end
        end
        -- 增加窗口高度，为下移提供空间
        mainFrame:SetHeight(mainFrame:GetHeight() + 30)
        layoutApplied = true
    end

    -- =======================
    -- 默认DKP输入窗口 (allDKPFrame，XyTrackerFrame 子框架)
    -- =======================
    local allDKPFrame = _G["allDKPFrame"]
    if SkinWindow(allDKPFrame) then
        SkinCloseButton(_G["allDKPFrameCloseButton"], allDKPFrame.backdrop, -6, -6)
        -- 注意：XyAddDkpFrameDone 全局名与 XyAddDkpFrame 的确定按钮重名，后者被遮蔽，此处处理的是实际生效的实例
        SkinPanelButton(_G["XyAddDkpFrameDone"])
        SkinEditBox(_G["allDKPFrameTXT"])
    end

    -- =======================
    -- 拾取列表窗口 (XyTrackerLootListFrame)
    -- =======================
    local lootFrame = _G["XyTrackerLootListFrame"]
    if SkinWindow(lootFrame) then
        SkinCloseButton(_G["XyTrackerLootListFrameCloseButton"], lootFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyTrackerLootListFrameRestoreButton"]) -- 恢复
        SkinPanelButton(_G["XyTrackerLootListFrameSaveButton"])    -- 保存
        SkinPanelButton(_G["XyTrackerLootListFrameClearButton"])   -- 清除列表

        -- 拾取列表表头（物品名称/归属玩家/使用分数/是否许愿/拾取时间）
        for i = 1, 5 do
            SkinColumnHeader(_G["LootFrameColumnHeader" .. i])
        end

        local lootScrollBar = _G["LootListScrollFrameScrollBar"]
        if lootScrollBar then
            SkinScrollbar(lootScrollBar)
        end
    end

    -- 品质筛选复选框（XyTrackerQualityFilterFrame 内，XML 已实例化，QualityFilter.lua 可能动态补建）
    local qualityChecks = {
        "OrangeQualityCheck", "PurpleQualityCheck", "BlueQualityCheck",
        "GreenQualityCheck", "WhiteQualityCheck",
    }
    for _, name in ipairs(qualityChecks) do
        local check = _G[name]
        if check and not check.pfUISkinned then
            check.pfUISkinned = true
            SkinCheckbox(check, 20)
        end
    end

    -- =======================
    -- 加/减分窗口 (XyAddDkpFrame / XyMinusDkpFrame)
    -- =======================
    local addFrame = _G["XyAddDkpFrame"]
    if SkinWindow(addFrame) then
        SkinCloseButton(_G["XyAddDkpFrameCloseButton"], addFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyAddDkpFrameDone"])
        SkinEditBox(_G["XyAddDkpFramePoint"])
    end

    local minusFrame = _G["XyMinusDkpFrame"]
    if SkinWindow(minusFrame) then
        SkinCloseButton(_G["XyMinusDkpFrameCloseButton"], minusFrame.backdrop, -6, -6)
        SkinPanelButton(_G["XyMinusDkpFrameDone"])
        SkinEditBox(_G["XyMinusDkpFramePoint"])
    end

    -- =======================
    -- 导出窗口 (XyExportFrame)
    -- =======================
    local exportFrame = _G["XyExportFrame"]
    if SkinWindow(exportFrame) then
        SkinEditBox(_G["XyExportEdit"])
    end

    -- =======================
    -- 宣言窗口 (XyTrackerDeclarationFrame)
    -- =======================
    local declFrame = _G["XyTrackerDeclarationFrame"]
    if SkinWindow(declFrame) then
        SkinPanelButton(_G["XyTrackerDeclarationConfirmButton"]) -- 保存
        SkinPanelButton(_G["XyTrackerDeclarationCancelButton"])  -- 取消
        SkinEditBox(_G["XyTrackerDeclarationLargeEditBox"])
    end

    -- =======================
    -- 黑名单配置窗口 (XyTrackerBlacklistConfigFrame)
    -- =======================
    local blFrame = _G["XyTrackerBlacklistConfigFrame"]
    if SkinWindow(blFrame) then
        -- 启用复选框
        local enableCheck = _G["XyTrackerBlacklistConfigFrameEnableCheckbox"]
        if enableCheck and not enableCheck.pfUISkinned then
            enableCheck.pfUISkinned = true
            SkinCheckbox(enableCheck, 20)
        end

        -- 输入框（InputBoxTemplate）
        local blEdits = {
            "XyTrackerBlacklistConfigFrameAnnouncementText",
            "XyTrackerBlacklistConfigFrameAddPlayerText",
            "XyTrackerBlacklistConfigFrameRemoveIndexEdit",
            "XyTrackerBlacklistConfigFrameReasonText",
        }
        for _, name in ipairs(blEdits) do
            SkinEditBox(_G[name])
        end

        -- 按钮（关闭按钮也是 UIPanelButtonTemplate，按普通按钮处理）
        local blButtons = {
            "XyTrackerBlacklistConfigFrameAddButton",
            "XyTrackerBlacklistConfigFrameRemoveButton",
            "XyTrackerBlacklistConfigFrameShowListButton",
            "XyTrackerBlacklistConfigFrameCloseButton",
        }
        for _, name in ipairs(blButtons) do
            SkinPanelButton(_G[name])
        end
    end

    -- =======================
    -- 开团公告编辑窗口 (XyTrackerStarttextEditBoxFrame，动态创建，可能尚不存在)
    -- =======================
    local stFrame = _G["XyTrackerStarttextEditBoxFrame"]
    if SkinWindow(stFrame) then
        SkinEditBox(_G["XyTrackerStarttextEditBox"])
        -- 保存/取消按钮未命名，遍历子框架处理
        for _, child in ipairs({stFrame:GetChildren()}) do
            if child:GetObjectType() == "Button" then
                SkinPanelButton(child)
            end
        end
    end

    return true
end

-- =======================
-- Hook 动态创建入口：开团公告编辑窗口首次打开时才创建
-- =======================
if XyTracker_ShowStarttextEditBox then
    local origShowStarttext = XyTracker_ShowStarttextEditBox
    XyTracker_ShowStarttextEditBox = function()
        local result = origShowStarttext()
        ApplySkin()
        return result
    end
end

-- =======================
-- 等待 pfUI 就绪后应用皮肤
-- =======================
local skinner = CreateFrame("Frame")
skinner:RegisterEvent("ADDON_LOADED")
skinner:RegisterEvent("PLAYER_LOGIN")
skinner:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "XyTracker" then
        -- XyTracker 加载完成，尝试应用皮肤
        if ApplySkin() then
            this:UnregisterAllEvents()
        end
    elseif event == "PLAYER_LOGIN" then
        -- 所有插件加载完毕后再次尝试（动态创建的控件那时已存在）
        if ApplySkin() then
            this:UnregisterAllEvents()
        end
    end
end)
