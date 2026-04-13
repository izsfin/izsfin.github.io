--[[ $$ Protogen Library || by its.lerp | v0.0.1 in dev || thanks for using :)s $$ ]]

local ProtogenUI = {}
ProtogenUI.__index = ProtogenUI

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

local function Color(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1,2), 16),
        tonumber(hex:sub(3,4), 16),
        tonumber(hex:sub(5,6), 16)
    )
end

local function HexToColor3(hex)
    local ok, r, g, b = pcall(function()
        hex = hex:gsub("#","")
        if #hex ~= 6 then error() end
        return
            tonumber(hex:sub(1,2),16),
            tonumber(hex:sub(3,4),16),
            tonumber(hex:sub(5,6),16)
    end)
    if ok and r then return Color3.fromRGB(r,g,b) end
    return nil
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, mousePos, framePos = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

local C = {
    BG           = Color("111111"),
    BG_ELEMENT   = Color("202020"),
    BG_INACTIVE  = Color("282828"),
    BG_INPUT     = Color("111111"),
    SEPARATOR    = Color("383838"),
    STROKE       = Color("0038F0"),
    TOGGLE_ON    = Color("3060FF"),
    TEXT         = Color("FFFFFF"),
    TRANSPARENT  = Color3.new(0,0,0),
}

local FONT   = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Regular)
local FONT_SZ = 13

local function addStroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.SEPARATOR
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = inst
    return s
end

local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = inst
    return c
end

local function addPadding(inst, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 4)
    p.PaddingBottom = UDim.new(0, bottom or 4)
    p.PaddingLeft   = UDim.new(0, left   or 6)
    p.PaddingRight  = UDim.new(0, right  or 6)
    p.Parent = inst
    return p
end

local function newLabel(parent, text, size, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = C.TEXT
    l.FontFace = FONT
    l.TextSize = size or FONT_SZ
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Size = UDim2.new(1,0,0,size and size+4 or FONT_SZ+4)
    l.Parent = parent
    return l
end

function ProtogenUI.Create(cfg)
    cfg = cfg or {}
    local title   = cfg.Title   or "ProtogenUI"
    local keybind = cfg.Keybind or Enum.KeyCode.RightShift

    if type(keybind) == "string" then
        keybind = Enum.KeyCode[keybind] or Enum.KeyCode.RightShift
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "ProtogenUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    pcall(function() sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    if not sg.Parent then sg.Parent = game:GetService("CoreGui") end

    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(0, 340, 0, 500)
    bg.Position = UDim2.new(0.5,-170,0.5,-250)
    bg.BackgroundColor3 = C.BG
    bg.BorderSizePixel = 0
    bg.Parent = sg
    addCorner(bg, 6)
    addStroke(bg, C.STROKE, 1.5)

    local titleCont = Instance.new("Frame")
    titleCont.Name = "TitleContainerFrame"
    titleCont.Size = UDim2.new(1,0,0,32)
    titleCont.BackgroundColor3 = C.BG_ELEMENT
    titleCont.BorderSizePixel = 0
    titleCont.Parent = bg
    addCorner(titleCont, 6)

    local titleBotFix = Instance.new("Frame")
    titleBotFix.Size = UDim2.new(1,0,0.5,0)
    titleBotFix.Position = UDim2.new(0,0,0.5,0)
    titleBotFix.BackgroundColor3 = C.BG_ELEMENT
    titleBotFix.BorderSizePixel = 0
    titleBotFix.ZIndex = 0
    titleBotFix.Parent = titleCont

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1,0,1,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = C.TEXT
    titleLabel.FontFace = FONT
    titleLabel.TextSize = FONT_SZ
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.ZIndex = 2
    titleLabel.Parent = titleCont

    makeDraggable(bg, titleCont)

    local tabCont = Instance.new("Frame")
    tabCont.Name = "TabContainerFrame"
    tabCont.Size = UDim2.new(1,0,0,26)
    tabCont.Position = UDim2.new(0,0,0,32)
    tabCont.BackgroundColor3 = C.BG
    tabCont.BorderSizePixel = 0
    tabCont.Parent = bg

    local function makeSep(name, size, pos)
        local s = Instance.new("Frame")
        s.Name = name
        s.Size = size
        s.Position = pos
        s.BackgroundColor3 = C.SEPARATOR
        s.BorderSizePixel = 0
        s.Parent = tabCont
        return s
    end
    makeSep("LeftSeparator",  UDim2.new(0,1,1,0), UDim2.new(0,0,0,0))
    makeSep("RightSeparator", UDim2.new(0,1,1,0), UDim2.new(1,-1,0,0))
    makeSep("UpSeparator",    UDim2.new(1,0,0,1), UDim2.new(0,0,0,0))

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0,2)
    tabLayout.Parent = tabCont
    addPadding(tabCont, 3, 3, 4, 4)

    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContentFrame"
    tabContent.Size = UDim2.new(1,0,1,-58)
    tabContent.Position = UDim2.new(0,0,0,58)
    tabContent.BackgroundColor3 = C.BG_ELEMENT
    tabContent.BorderSizePixel = 0
    tabContent.ClipsDescendants = true
    tabContent.Parent = bg

    local visible = true
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == keybind then
            visible = not visible
            bg.Visible = visible
        end
    end)

    local Window = {}
    Window._sg          = sg
    Window._bg          = bg
    Window._tabCont     = tabCont
    Window._tabContent  = tabContent
    Window._tabs        = {}
    Window._activeTab   = nil

    function Window:TabCreate(cfg2)
        cfg2 = cfg2 or {}
        local tabTitle   = cfg2.Title       or "Tab"
        local openOnStart = cfg2.OpenOnStart ~= false

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabLabel"
        tabBtn.AutoButtonColor = false
        tabBtn.Size = UDim2.new(0, 80, 1, 0)
        tabBtn.BackgroundColor3 = C.BG_INACTIVE
        tabBtn.Text = tabTitle
        tabBtn.TextColor3 = C.TEXT
        tabBtn.FontFace = FONT
        tabBtn.TextSize = FONT_SZ - 1
        tabBtn.Parent = self._tabCont
        addCorner(tabBtn, 3)

        local contentHolder = Instance.new("Frame")
        contentHolder.Name = "ContentHolder_"..tabTitle
        contentHolder.Size = UDim2.new(1,0,1,0)
        contentHolder.BackgroundTransparency = 1
        contentHolder.Visible = false
        contentHolder.Parent = self._tabContent

        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Scroll"
        scroll.Size = UDim2.new(1,0,1,0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = C.STROKE
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = contentHolder

        local scrollLayout = Instance.new("UIListLayout")
        scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        scrollLayout.Padding = UDim.new(0,4)
        scrollLayout.Parent = scroll
        addPadding(scroll, 6, 6, 6, 6)

        local Tab = {}
        Tab._btn      = tabBtn
        Tab._holder   = contentHolder
        Tab._scroll   = scroll
        Tab._layout   = scrollLayout
        Tab._window   = self
        Tab._sections = {}

        local function setActive(t)
            for _, tb in ipairs(self._tabs) do
                tb._btn.BackgroundColor3 = C.BG_INACTIVE
                tb._holder.Visible = false
            end

            t._btn.BackgroundColor3 = C.BG_ELEMENT
            t._holder.Visible = true
            self._activeTab = t
        end

        tabBtn.MouseButton1Click:Connect(function()
            setActive(Tab)
        end)

        table.insert(self._tabs, Tab)

        if openOnStart and #self._tabs == 1 then
            setActive(Tab)
        end

        function Tab:SectionCreate(cfg3)
            cfg3 = cfg3 or {}
            local t1 = cfg3.Title_1 or "Section"
            local t2 = cfg3.Title_2 or nil

            local secOuter = Instance.new("Frame")
            secOuter.Name = "Tab2ContainerFrame"
            secOuter.Size = UDim2.new(1,0,0,0)
            secOuter.AutomaticSize = Enum.AutomaticSize.Y
            secOuter.BackgroundColor3 = C.BG_INACTIVE
            secOuter.BorderSizePixel = 0
            secOuter.Parent = self._scroll
            addCorner(secOuter, 4)
            addStroke(secOuter, C.SEPARATOR, 1)

            local secOuterLayout = Instance.new("UIListLayout")
            secOuterLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secOuterLayout.Padding = UDim.new(0,0)
            secOuterLayout.Parent = secOuter

            local secHeader = Instance.new("Frame")
            secHeader.Name = "SectionHeader"
            secHeader.Size = UDim2.new(1,0,0,24)
            secHeader.BackgroundColor3 = C.BG_ELEMENT
            secHeader.BorderSizePixel = 0
            secHeader.LayoutOrder = 0
            secHeader.Parent = secOuter
            addCorner(secHeader, 4)

            local secHeaderLayout = Instance.new("UIListLayout")
            secHeaderLayout.FillDirection = Enum.FillDirection.Horizontal
            secHeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secHeaderLayout.Padding = UDim.new(0,2)
            secHeaderLayout.Parent = secHeader
            addPadding(secHeader, 2, 2, 4, 4)

            local panes = {}

            local function makePane(name, idx)
                local pane = Instance.new("Frame")
                pane.Name = "Pane_"..name
                pane.Size = UDim2.new(1,0,0,0)
                pane.AutomaticSize = Enum.AutomaticSize.Y
                pane.BackgroundColor3 = C.BG
                pane.BorderSizePixel = 0
                pane.LayoutOrder = idx + 1
                pane.Visible = false
                pane.Parent = secOuter

                local paneLayout = Instance.new("UIListLayout")
                paneLayout.SortOrder = Enum.SortOrder.LayoutOrder
                paneLayout.Padding = UDim.new(0,2)
                paneLayout.Parent = pane
                addPadding(pane, 4, 4, 4, 4)

                return pane
            end

            local pane1 = makePane(t1, 1)
            pane1.Visible = true
            panes[t1] = pane1

            local pane2
            if t2 then
                pane2 = makePane(t2, 2)
                panes[t2] = pane2
            end

            local activePaneRef = { v = pane1 }

            local function makeSubTabBtn(label, pane, lo)
                local btn = Instance.new("TextButton")
                btn.AutoButtonColor = false
                btn.Size = UDim2.new(0, t2 and 74 or 80, 1, 0)
                btn.BackgroundColor3 = (lo == 1) and C.BG or C.BG_INACTIVE
                btn.Text = label
                btn.TextColor3 = C.TEXT
                btn.FontFace = FONT
                btn.TextSize = FONT_SZ - 2
                btn.LayoutOrder = lo
                btn.Parent = secHeader
                addCorner(btn, 3)

                btn.MouseButton1Click:Connect(function()
                    activePaneRef.v.Visible = false
                    pane.Visible = true
                    activePaneRef.v = pane
                    for _, ch in ipairs(secHeader:GetChildren()) do
                        if ch:IsA("TextButton") then
                            ch.BackgroundColor3 = C.BG_INACTIVE
                        end
                    end
                    btn.BackgroundColor3 = C.BG_ELEMENT
                end)
                return btn
            end

            makeSubTabBtn(t1, pane1, 1)
            if t2 then makeSubTabBtn(t2, pane2, 2) end

            local Section = {}
            Section._secOuter = secOuter
            Section._panes    = panes
            Section._activePane = pane1
            Section._tab      = self

            local function getPane(paneName)
                if paneName then return panes[paneName] end
                return activePaneRef.v
            end

            function Section:AddLabel(cfg4)
                cfg4 = cfg4 or {}
                local word    = cfg4.Word    or "Label"
                local content = cfg4.Content or ""
                local pane    = getPane(cfg4.Pane)

                local fr = Instance.new("Frame")
                fr.Name = "TLFrame"
                fr.Size = UDim2.new(1,0,0,24)
                fr.BackgroundTransparency = 1
                fr.BorderSizePixel = 0
                fr.Parent = pane

                local layout = Instance.new("UIListLayout")
                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Padding = UDim.new(0,5)
                layout.Parent = fr

                local wl = Instance.new("TextLabel")
                wl.Name = "WordLabel"
                wl.BackgroundTransparency = 1
                wl.Text = word
                wl.TextColor3 = C.TEXT
                wl.FontFace = FONT
                wl.TextSize = FONT_SZ
                wl.TextXAlignment = Enum.TextXAlignment.Left
                wl.AutomaticSize = Enum.AutomaticSize.X
                wl.Size = UDim2.new(0,0,1,0)
                wl.Parent = fr

                local colon = Instance.new("TextLabel")
                colon.BackgroundTransparency = 1
                colon.Text = ":"
                colon.TextColor3 = C.TEXT
                colon.FontFace = FONT
                colon.TextSize = FONT_SZ
                colon.Size = UDim2.new(0,6,1,0)
                colon.TextXAlignment = Enum.TextXAlignment.Center
                colon.Parent = fr

                local wu = Instance.new("TextLabel")
                wu.Name = "WordToUse"
                wu.BackgroundTransparency = 1
                wu.Text = content
                wu.TextColor3 = C.TEXT
                wu.FontFace = FONT
                wu.TextSize = FONT_SZ
                wu.TextXAlignment = Enum.TextXAlignment.Left
                wu.AutomaticSize = Enum.AutomaticSize.X
                wu.Size = UDim2.new(0,0,1,0)
                wu.Parent = fr

                local Elem = {}
                function Elem:SetContent(v) wu.Text = tostring(v) end
                return Elem
            end

            function Section:AddToggle(cfg4)
                cfg4 = cfg4 or {}
                local label    = cfg4.Title    or "Toggle"
                local default  = cfg4.Default  or false
                local callback = cfg4.Callback or function() end
                local pane     = getPane(cfg4.Pane)

                local state = default

                local fr = Instance.new("Frame")
                fr.Name = "TFrame"
                fr.Size = UDim2.new(1,0,0,24)
                fr.BackgroundTransparency = 1
                fr.BorderSizePixel = 0
                fr.Parent = pane

                local bg2 = Instance.new("Frame")
                bg2.Name = "Background"
                bg2.Size = UDim2.new(0,36,0,18)
                bg2.Position = UDim2.new(0,0,0.5,-9)
                bg2.BackgroundColor3 = C.BG_INACTIVE
                bg2.BorderSizePixel = 0
                bg2.Parent = fr
                addCorner(bg2, 9)
                addStroke(bg2, C.SEPARATOR, 1)

                local thumb = Instance.new("Frame")
                thumb.Name = "Included"
                thumb.Size = UDim2.new(0,12,0,12)
                thumb.Position = UDim2.new(0,3,0.5,-6)
                thumb.BackgroundColor3 = state and C.TOGGLE_ON or C.SEPARATOR
                thumb.BorderSizePixel = 0
                thumb.Parent = bg2
                addCorner(thumb, 6)

                local lbl = Instance.new("TextLabel")
                lbl.Name = "Label"
                lbl.BackgroundTransparency = 1
                lbl.Text = label
                lbl.TextColor3 = C.TEXT
                lbl.FontFace = FONT
                lbl.TextSize = FONT_SZ
                lbl.Position = UDim2.new(0,44,0,0)
                lbl.Size = UDim2.new(1,-44,1,0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = fr

                local function updateVisual()
                    local tw = TweenService:Create(thumb, TweenInfo.new(0.15), {
                        Position = state
                            and UDim2.new(0,21,0.5,-6)
                            or  UDim2.new(0,3,0.5,-6),
                        BackgroundColor3 = state and C.TOGGLE_ON or C.SEPARATOR
                    })
                    tw:Play()
                end

                updateVisual()

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,1,0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.Parent = fr

                btn.MouseButton1Click:Connect(function()
                    state = not state
                    updateVisual()
                    pcall(callback, state)
                end)

                local Elem = {}
                Elem._state = state
                function Elem:Set(v)
                    state = v
                    updateVisual()
                end
                function Elem:Get() return state end
                return Elem
            end

            function Section:AddSlider(cfg4)
                cfg4 = cfg4 or {}
                local label    = cfg4.Title    or "Slider"
                local min      = cfg4.Min      or 0
                local max      = cfg4.Max      or 100
                local default  = cfg4.Default  or min
                local callback = cfg4.Callback or function() end
                local pane     = getPane(cfg4.Pane)

                local val = math.clamp(default, min, max)

                local fr = Instance.new("Frame")
                fr.Name = "SFrame"
                fr.Size = UDim2.new(1,0,0,38)
                fr.BackgroundTransparency = 1
                fr.BorderSizePixel = 0
                fr.Parent = pane

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Name = "Title"
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text = label
                titleLbl.TextColor3 = C.TEXT
                titleLbl.FontFace = FONT
                titleLbl.TextSize = FONT_SZ
                titleLbl.Size = UDim2.new(1,0,0,16)
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.Parent = fr

                local sep = Instance.new("Frame")
                sep.Name = "Separator"
                sep.Size = UDim2.new(1,0,0,18)
                sep.Position = UDim2.new(0,0,0,18)
                sep.BackgroundColor3 = C.BG_ELEMENT
                sep.BorderSizePixel = 0
                sep.Parent = fr
                addCorner(sep, 4)
                addStroke(sep, C.SEPARATOR, 1)

                local track = Instance.new("Frame")
                track.Name = "Background"
                track.Size = UDim2.new(1,-2,1,-2)
                track.Position = UDim2.new(0,1,0,1)
                track.BackgroundColor3 = C.BG
                track.BorderSizePixel = 0
                track.ClipsDescendants = true
                track.Parent = sep
                addCorner(track, 3)

                local hl = Instance.new("Frame")
                hl.Name = "Highlighted"
                hl.Size = UDim2.new((val-min)/(max-min),0,1,0)
                hl.BackgroundColor3 = C.TOGGLE_ON
                hl.BorderSizePixel = 0
                hl.Parent = track
                addCorner(hl, 3)

                local holder = Instance.new("TextLabel")
                holder.Name = "Holder"
                holder.BackgroundTransparency = 1
                holder.Text = tostring(val)
                holder.TextColor3 = C.TEXT
                holder.FontFace = FONT
                holder.TextSize = FONT_SZ - 1
                holder.Size = UDim2.new(1,0,1,0)
                holder.TextXAlignment = Enum.TextXAlignment.Center
                holder.ZIndex = 3
                holder.Parent = sep

                local sliding = false
                sep.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = (input.Position.X - sep.AbsolutePosition.X) / sep.AbsoluteSize.X
                        rel = math.clamp(rel, 0, 1)
                        val = math.floor(min + rel*(max-min) + 0.5)
                        hl.Size = UDim2.new((val-min)/(max-min),0,1,0)
                        holder.Text = tostring(val)
                        pcall(callback, val)
                    end
                end)

                local Elem = {}
                function Elem:Set(v)
                    val = math.clamp(v, min, max)
                    hl.Size = UDim2.new((val-min)/(max-min),0,1,0)
                    holder.Text = tostring(val)
                end
                function Elem:Get() return val end
                return Elem
            end

            function Section:AddTextBox(cfg4)
                cfg4 = cfg4 or {}
                local label      = cfg4.Title       or "TextBox"
                local placeholder= cfg4.Placeholder or "TextHolder"
                local callback   = cfg4.Callback    or function() end
                local pane       = getPane(cfg4.Pane)

                local fr = Instance.new("Frame")
                fr.Name = "TBFrame"
                fr.Size = UDim2.new(1,0,0,38)
                fr.BackgroundTransparency = 1
                fr.BorderSizePixel = 0
                fr.Parent = pane

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Name = "Title"
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text = label
                titleLbl.TextColor3 = C.TEXT
                titleLbl.FontFace = FONT
                titleLbl.TextSize = FONT_SZ
                titleLbl.Size = UDim2.new(1,0,0,16)
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.Parent = fr

                local sep = Instance.new("Frame")
                sep.Name = "Separator"
                sep.Size = UDim2.new(1,0,0,18)
                sep.Position = UDim2.new(0,0,0,18)
                sep.BackgroundColor3 = C.SEPARATOR
                sep.BorderSizePixel = 0
                sep.Parent = fr
                addCorner(sep, 4)

                local bgBox = Instance.new("Frame")
                bgBox.Name = "Background"
                bgBox.Size = UDim2.new(1,-2,1,-2)
                bgBox.Position = UDim2.new(0,1,0,1)
                bgBox.BackgroundColor3 = C.BG_INPUT
                bgBox.BorderSizePixel = 0
                bgBox.Parent = sep
                addCorner(bgBox, 3)

                local tb = Instance.new("TextBox")
                tb.Name = "Holder"
                tb.Size = UDim2.new(1,0,1,0)
                tb.BackgroundTransparency = 1
                tb.Text = ""
                tb.PlaceholderText = placeholder
                tb.PlaceholderColor3 = Color3.fromRGB(120,120,120)
                tb.TextColor3 = C.TEXT
                tb.FontFace = FONT
                tb.TextSize = FONT_SZ - 1
                tb.ClearTextOnFocus = false
                tb.Parent = bgBox
                addPadding(tb, 0,0,4,4)

                tb.FocusLost:Connect(function(enter)
                    if enter then pcall(callback, tb.Text) end
                end)

                local Elem = {}
                function Elem:Get() return tb.Text end
                function Elem:Set(v) tb.Text = v end
                return Elem
            end

            function Section:AddColorPicker(cfg4)
                cfg4 = cfg4 or {}
                local label    = cfg4.Title    or "ColorPicker"
                local default  = cfg4.Default  or Color3.fromRGB(255,0,0)
                local callback = cfg4.Callback or function() end
                local pane     = getPane(cfg4.Pane)

                local currentColor = default

                local fr = Instance.new("Frame")
                fr.Name = "CPFrame"
                fr.Size = UDim2.new(1,0,0,38)
                fr.BackgroundTransparency = 1
                fr.BorderSizePixel = 0
                fr.Parent = pane

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1,0,0,16)
                row.BackgroundTransparency = 1
                row.Parent = fr

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Name = "Title"
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text = label
                titleLbl.TextColor3 = C.TEXT
                titleLbl.FontFace = FONT
                titleLbl.TextSize = FONT_SZ
                titleLbl.Size = UDim2.new(1,-46,1,0)
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.Parent = row

                local swatch = Instance.new("Frame")
                swatch.Name = "SelectedColor"
                swatch.Size = UDim2.new(0,40,0,14)
                swatch.Position = UDim2.new(1,-40,0,1)
                swatch.BackgroundColor3 = currentColor
                swatch.BorderSizePixel = 0
                swatch.Parent = row
                addCorner(swatch, 3)
                addStroke(swatch, C.SEPARATOR, 1)

                local inputRow = Instance.new("Frame")
                inputRow.Size = UDim2.new(1,0,0,18)
                inputRow.Position = UDim2.new(0,0,0,20)
                inputRow.BackgroundTransparency = 1
                inputRow.Parent = fr

                local sep2 = Instance.new("Frame")
                sep2.Name = "Separator"
                sep2.Size = UDim2.new(1,0,1,0)
                sep2.BackgroundColor3 = C.SEPARATOR
                sep2.BorderSizePixel = 0
                sep2.Parent = inputRow
                addCorner(sep2, 4)

                local bgBox2 = Instance.new("Frame")
                bgBox2.Name = "Background"
                bgBox2.Size = UDim2.new(1,-2,1,-2)
                bgBox2.Position = UDim2.new(0,1,0,1)
                bgBox2.BackgroundColor3 = C.BG_INPUT
                bgBox2.BorderSizePixel = 0
                bgBox2.Parent = sep2
                addCorner(bgBox2, 3)

                local hexPrefix = Instance.new("TextLabel")
                hexPrefix.BackgroundTransparency = 1
                hexPrefix.Text = "#"
                hexPrefix.TextColor3 = Color3.fromRGB(150,150,150)
                hexPrefix.FontFace = FONT
                hexPrefix.TextSize = FONT_SZ - 1
                hexPrefix.Size = UDim2.new(0,14,1,0)
                hexPrefix.TextXAlignment = Enum.TextXAlignment.Center
                hexPrefix.Parent = bgBox2

                local hexBox = Instance.new("TextBox")
                hexBox.Name = "RBox"
                hexBox.Size = UDim2.new(1,-14,1,0)
                hexBox.Position = UDim2.new(0,14,0,0)
                hexBox.BackgroundTransparency = 1
                hexBox.Text = string.format("%02X%02X%02X",
                    math.floor(default.R*255),
                    math.floor(default.G*255),
                    math.floor(default.B*255))
                hexBox.PlaceholderText = "RRGGBB"
                hexBox.PlaceholderColor3 = Color3.fromRGB(120,120,120)
                hexBox.TextColor3 = C.TEXT
                hexBox.FontFace = FONT
                hexBox.TextSize = FONT_SZ - 1
                hexBox.ClearTextOnFocus = false
                hexBox.Parent = bgBox2

                local function applyHex(txt)
                    local c = HexToColor3(txt)
                    if c then
                        currentColor = c
                        swatch.BackgroundColor3 = c
                        pcall(callback, c)
                    end
                end

                hexBox:GetPropertyChangedSignal("Text"):Connect(function()
                    if #hexBox.Text == 6 then
                        applyHex(hexBox.Text)
                    end
                end)
                hexBox.FocusLost:Connect(function(enter)
                    if enter then applyHex(hexBox.Text) end
                end)

                local Elem = {}
                function Elem:Get() return currentColor end
                function Elem:Set(c)
                    currentColor = c
                    swatch.BackgroundColor3 = c
                    hexBox.Text = string.format("%02X%02X%02X",
                        math.floor(c.R*255),
                        math.floor(c.G*255),
                        math.floor(c.B*255))
                end
                return Elem
            end

            function Section:AddDropdown(cfg4)
                cfg4 = cfg4 or {}
                local label    = cfg4.Title    or "Dropdown"
                local options  = cfg4.Options  or {}
                local default  = cfg4.Default  or (options[1] or "")
                local callback = cfg4.Callback or function() end
                local pane     = getPane(cfg4.Pane)

                local selected = default
                local open     = false

                local fr = Instance.new("Frame")
                fr.Name = "DDFrame"
                fr.Size = UDim2.new(1,0,0,38)
                fr.AutomaticSize = Enum.AutomaticSize.Y
                fr.BackgroundTransparency = 1
                fr.BorderSizePixel = 0
                fr.ClipsDescendants = false
                fr.Parent = pane

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Name = "Title"
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text = label
                titleLbl.TextColor3 = C.TEXT
                titleLbl.FontFace = FONT
                titleLbl.TextSize = FONT_SZ
                titleLbl.Size = UDim2.new(1,0,0,16)
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.Parent = fr

                local sep3 = Instance.new("Frame")
                sep3.Name = "Separator"
                sep3.Size = UDim2.new(1,0,0,18)
                sep3.Position = UDim2.new(0,0,0,18)
                sep3.BackgroundColor3 = C.SEPARATOR
                sep3.BorderSizePixel = 0
                sep3.ZIndex = 2
                sep3.Parent = fr
                addCorner(sep3, 4)

                local headerBg = Instance.new("Frame")
                headerBg.Size = UDim2.new(1,-2,1,-2)
                headerBg.Position = UDim2.new(0,1,0,1)
                headerBg.BackgroundColor3 = C.BG_INPUT
                headerBg.BorderSizePixel = 0
                headerBg.ZIndex = 2
                headerBg.Parent = sep3
                addCorner(headerBg, 3)

                local holderLbl = Instance.new("TextLabel")
                holderLbl.Name = "Holder"
                holderLbl.BackgroundTransparency = 1
                holderLbl.Text = selected
                holderLbl.TextColor3 = C.TEXT
                holderLbl.FontFace = FONT
                holderLbl.TextSize = FONT_SZ - 1
                holderLbl.Size = UDim2.new(1,-16,1,0)
                holderLbl.TextXAlignment = Enum.TextXAlignment.Left
                holderLbl.ZIndex = 3
                holderLbl.Parent = headerBg
                addPadding(holderLbl, 0,0,4,0)

                local arrow = Instance.new("TextLabel")
                arrow.BackgroundTransparency = 1
                arrow.Text = "▾"
                arrow.TextColor3 = C.TEXT
                arrow.FontFace = FONT
                arrow.TextSize = FONT_SZ
                arrow.Size = UDim2.new(0,16,1,0)
                arrow.Position = UDim2.new(1,-16,0,0)
                arrow.TextXAlignment = Enum.TextXAlignment.Center
                arrow.ZIndex = 3
                arrow.Parent = headerBg

                local listBg = Instance.new("Frame")
                listBg.Name = "Background"
                listBg.Size = UDim2.new(1,0,0,0)
                listBg.Position = UDim2.new(0,0,0,38)
                listBg.BackgroundColor3 = C.BG_INPUT
                listBg.BorderSizePixel = 0
                listBg.Visible = false
                listBg.ZIndex = 10
                listBg.ClipsDescendants = true
                listBg.Parent = fr
                addCorner(listBg, 4)
                addStroke(listBg, C.SEPARATOR, 1)

                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Padding = UDim.new(0,1)
                listLayout.Parent = listBg
                addPadding(listBg, 2,2,2,2)

                for i, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.AutoButtonColor = false
                    optBtn.Size = UDim2.new(1,0,0,18)
                    optBtn.BackgroundColor3 = C.BG_ELEMENT
                    optBtn.Text = opt
                    optBtn.TextColor3 = C.TEXT
                    optBtn.FontFace = FONT
                    optBtn.TextSize = FONT_SZ - 1
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left
                    optBtn.ZIndex = 11
                    optBtn.LayoutOrder = i
                    optBtn.Parent = listBg
                    addPadding(optBtn, 0,0,4,4)
                    addCorner(optBtn, 3)

                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        holderLbl.Text = opt
                        open = false
                        listBg.Visible = false
                        arrow.Text = "▾"
                        fr.Size = UDim2.new(1,0,0,38)
                        pcall(callback, opt)
                    end)
                end

                listBg.Size = UDim2.new(1,0,0, #options * 20 + 4)

                local headerBtn = Instance.new("TextButton")
                headerBtn.Size = UDim2.new(1,0,1,0)
                headerBtn.BackgroundTransparency = 1
                headerBtn.Text = ""
                headerBtn.ZIndex = 4
                headerBtn.Parent = headerBg

                headerBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listBg.Visible = open
                    arrow.Text = open and "▴" or "▾"
                    if open then
                        fr.Size = UDim2.new(1,0,0, 38 + #options*20 + 8)
                    else
                        fr.Size = UDim2.new(1,0,0,38)
                    end
                end)

                local Elem = {}
                function Elem:Get() return selected end
                function Elem:Set(v)
                    selected = v
                    holderLbl.Text = v
                end
                function Elem:SetOptions(opts)
                    options = opts
                    for _, ch in ipairs(listBg:GetChildren()) do
                        if ch:IsA("TextButton") then ch:Destroy() end
                    end
                    for i, opt in ipairs(opts) do
                        local ob = Instance.new("TextButton")
                        ob.AutoButtonColor = false
                        ob.Size = UDim2.new(1,0,0,18)
                        ob.BackgroundColor3 = C.BG_ELEMENT
                        ob.Text = opt
                        ob.TextColor3 = C.TEXT
                        ob.FontFace = FONT
                        ob.TextSize = FONT_SZ - 1
                        ob.TextXAlignment = Enum.TextXAlignment.Left
                        ob.ZIndex = 11
                        ob.LayoutOrder = i
                        ob.Parent = listBg
                        addPadding(ob, 0,0,4,4)
                        addCorner(ob, 3)
                        ob.MouseButton1Click:Connect(function()
                            selected = opt
                            holderLbl.Text = opt
                            open = false
                            listBg.Visible = false
                            arrow.Text = "▾"
                            fr.Size = UDim2.new(1,0,0,38)
                            pcall(callback, opt)
                        end)
                    end
                    listBg.Size = UDim2.new(1,0,0, #opts*20+4)
                end
                return Elem
            end
            return Section
        end
        return Tab
    end
    return Window
end
return ProtogenUI