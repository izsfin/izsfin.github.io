--[[ Primordial.cc Library | v0.0.3t | Dev - selfweather ]]
local TweenService = game:GetService("TweenService")
local UI = {}
local C = {
    bg        = Color3.fromRGB(25, 25, 25),
    border    = Color3.fromRGB(143, 248, 240),
    borderDim = Color3.fromRGB(40, 40, 40),
    text      = Color3.fromRGB(220, 220, 230),
    textMuted = Color3.fromRGB(170, 170, 175),
    textDim   = Color3.fromRGB(100, 100, 110),
    sep       = Color3.fromRGB(143, 248, 240),
    accent    = Color3.fromRGB(143, 248, 240),
    innerBg   = Color3.fromRGB(13, 13, 13),
    subBg     = Color3.fromRGB(10, 10, 10),
}

local TF = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local TM = TweenInfo.new(0.22, Enum.EasingStyle.Quad)
local HEADER_H   = 28
local ITEM_H     = 26
local SUBH       = 24
local SUB_ITEM_H = 22
local PAD_X      = 12
local PAD_Y_T    = 8
local PAD_Y_B    = 10
local GAP        = 3
local SEP_H      = 1

local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
end

local function mkStroke(p, col, th, tr)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.borderDim
    s.Thickness = th or 0.5
    s.Transparency = tr or 0
    return s
end

local function mkList(p, gap)
    local l = Instance.new("UIListLayout", p)
    l.Padding = UDim.new(0, gap or GAP)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    return l
end

local function mkInnerBtn(parent, text, fontSize, height, bg, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, height or ITEM_H)
    b.BackgroundColor3 = bg or C.innerBg
    b.BackgroundTransparency = 0.1
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.Text = "  " .. text
    b.TextSize = fontSize or 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextColor3 = C.textMuted
    mkCorner(b, 6)
    mkStroke(b, C.borderDim, 0.5, 0.85)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TF, {BackgroundTransparency = 0}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TF, {BackgroundTransparency = 0.1}):Play()
    end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function mkSubfunc(parent, text, btns, onResize)
    local closedH = SUBH
    local innerH  = PAD_Y_T + PAD_Y_B
    for i = 1, #btns do
        innerH = innerH + SUB_ITEM_H
        if i < #btns then innerH = innerH + GAP end
    end
    local openH  = closedH + SEP_H + 2 + innerH
    local isOpen = false

    local shell = Instance.new("Frame", parent)
    shell.Size = UDim2.new(1, 0, 0, closedH)
    shell.BackgroundColor3 = C.innerBg
    shell.BackgroundTransparency = 0.1
    shell.BorderSizePixel = 0
    shell.ClipsDescendants = true
    mkCorner(shell, 6)
    mkStroke(shell, C.borderDim, 0.5, 0.85)

    local hdr = Instance.new("TextButton", shell)
    hdr.Size = UDim2.new(1, 0, 0, closedH)
    hdr.BackgroundTransparency = 1
    hdr.BorderSizePixel = 0
    hdr.Font = Enum.Font.Gotham
    hdr.Text = "  " .. text
    hdr.TextSize = 11
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.TextColor3 = C.textDim

    local arr = Instance.new("TextLabel", hdr)
    arr.Size = UDim2.new(0, 20, 1, 0)
    arr.Position = UDim2.new(1, -22, 0, 0)
    arr.BackgroundTransparency = 1
    arr.Font = Enum.Font.Gotham
    arr.Text = "▼"
    arr.TextSize = 9
    arr.TextColor3 = C.textDim

    local sep = Instance.new("Frame", shell)
    sep.Size = UDim2.new(1, -12, 0, SEP_H)
    sep.Position = UDim2.new(0, 6, 0, closedH)
    sep.BackgroundColor3 = C.sep
    sep.BackgroundTransparency = 0.9
    sep.BorderSizePixel = 0
    sep.Visible = false

    local cont = Instance.new("Frame", shell)
    cont.Position = UDim2.new(0, 0, 0, closedH + SEP_H + 1)
    cont.Size = UDim2.new(1, 0, 0, innerH)
    cont.BackgroundTransparency = 1
    cont.BorderSizePixel = 0
    cont.Visible = false

    local uipad = Instance.new("UIPadding", cont)
    uipad.PaddingLeft   = UDim.new(0, 8)
    uipad.PaddingRight  = UDim.new(0, 8)
    uipad.PaddingTop    = UDim.new(0, PAD_Y_T)
    uipad.PaddingBottom = UDim.new(0, PAD_Y_B)
    mkList(cont, GAP)

    for _, bd in ipairs(btns) do
        mkInnerBtn(cont, bd[1], 11, SUB_ITEM_H, C.subBg, bd[2])
    end

    hdr.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        sep.Visible = isOpen
        cont.Visible = isOpen
        local targetH = isOpen and openH or closedH
        TweenService:Create(shell, TM, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
        TweenService:Create(arr, TF, {Rotation = isOpen and 180 or 0}):Play()
        if onResize then
            local delta = isOpen and (openH - closedH) or (closedH - openH)
            onResize(delta)
        end
    end)

    local function getH() return isOpen and openH or closedH end
    return shell, getH
end

local function buildContainer(shell, items, yOffset, onShellResize)
    local sep = Instance.new("Frame", shell)
    sep.Size = UDim2.new(1, -PAD_X * 2, 0, SEP_H)
    sep.Position = UDim2.new(0, PAD_X, 0, yOffset)
    sep.BackgroundColor3 = C.sep
    sep.BackgroundTransparency = 0.82
    sep.BorderSizePixel = 0
    sep.Visible = false

    local cont = Instance.new("Frame", shell)
    cont.Position = UDim2.new(0, 0, 0, yOffset + SEP_H + 1)
    cont.BackgroundTransparency = 1
    cont.BorderSizePixel = 0
    cont.Visible = false

    local uipad = Instance.new("UIPadding", cont)
    uipad.PaddingLeft   = UDim.new(0, PAD_X)
    uipad.PaddingRight  = UDim.new(0, PAD_X)
    uipad.PaddingTop    = UDim.new(0, PAD_Y_T)
    uipad.PaddingBottom = UDim.new(0, PAD_Y_B)
    mkList(cont, GAP)

    local baseH = PAD_Y_T + PAD_Y_B
    local currentH = 0
    local sfGetters = {}
    for i, item in ipairs(items) do
        local isLast = (i == #items)

        if item.type == "button" then
            mkInnerBtn(cont, item.text, 12, ITEM_H, C.innerBg, item.callback)
            baseH = baseH + ITEM_H + (isLast and 0 or GAP)

        elseif item.type == "subfunc" then
            -- передаём onResize чтобы субфункция сообщала о раскрытии
            local sf, getH = mkSubfunc(cont, item.text, item.buttons or {}, function(delta)
                currentH = currentH + delta
                if onShellResize then onShellResize(currentH) end
            end)
            table.insert(sfGetters, getH)
            baseH = baseH + SUBH + (isLast and 0 or GAP)

        elseif item.type == "setting_input" then
            local row = Instance.new("Frame", cont)
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0

            local lbl = Instance.new("TextLabel", row)
            lbl.Size = UDim2.new(0.5, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.Text = item.label
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextColor3 = C.textDim

            local tb = Instance.new("TextBox", row)
            tb.Size = UDim2.new(0, 80, 0, 20)
            tb.Position = UDim2.new(1, -80, 0.5, -10)
            tb.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            tb.BackgroundTransparency = 0
            tb.BorderSizePixel = 0
            tb.Font = Enum.Font.Gotham
            tb.Text = tostring(item.default or "")
            tb.TextSize = 11
            tb.TextColor3 = C.text
            tb.ClearTextOnFocus = false
            mkCorner(tb, 4)
            mkStroke(tb, C.borderDim, 0.5, 0.6)
            local p2 = Instance.new("UIPadding", tb)
            p2.PaddingLeft = UDim.new(0, 6)

            baseH = baseH + 24 + (isLast and 0 or GAP)

        elseif item.type == "setting_toggle" then
            local togOn = item.default or false
            local row = Instance.new("Frame", cont)
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0

            local lbl = Instance.new("TextLabel", row)
            lbl.Size = UDim2.new(0.6, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.Text = item.label
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextColor3 = C.textDim

            local track = Instance.new("TextButton", row)
            track.Size = UDim2.new(0, 28, 0, 14)
            track.Position = UDim2.new(1, -30, 0.5, -7)
            track.BackgroundColor3 = togOn and C.accent or Color3.fromRGB(40, 40, 40)
            track.BackgroundTransparency = togOn and 0.7 or 0
            track.BorderSizePixel = 0
            track.Text = ""
            mkCorner(track, 7)
            mkStroke(track, togOn and C.accent or C.borderDim, 0.5, 0)

            local thumb = Instance.new("Frame", track)
            thumb.Size = UDim2.new(0, 9, 0, 9)
            thumb.Position = togOn
                and UDim2.new(1, -11, 0.5, -4.5)
                or  UDim2.new(0,   2, 0.5, -4.5)
            thumb.BackgroundColor3 = togOn and C.accent or Color3.fromRGB(90, 90, 90)
            thumb.BorderSizePixel = 0
            mkCorner(thumb, 5)

            track.MouseButton1Click:Connect(function()
                togOn = not togOn
                TweenService:Create(track, TF, {
                    BackgroundColor3     = togOn and C.accent or Color3.fromRGB(40, 40, 40),
                    BackgroundTransparency = togOn and 0.7 or 0,
                }):Play()
                TweenService:Create(thumb, TF, {
                    Position           = togOn and UDim2.new(1,-11,0.5,-4.5) or UDim2.new(0,2,0.5,-4.5),
                    BackgroundColor3   = togOn and C.accent or Color3.fromRGB(90, 90, 90),
                }):Play()
                if item.callback then item.callback(togOn) end
            end)

            baseH = baseH + 24 + (isLast and 0 or GAP)
        end
    end

    currentH = baseH
    cont.Size = UDim2.new(1, 0, 0, baseH)

    local function getH() return currentH end
    return cont, sep, getH
end

local function makeShell(parent, withDot)
    local shell = Instance.new("Frame", parent)
    shell.Size = UDim2.new(1, 0, 0, HEADER_H)
    shell.BackgroundColor3 = C.bg
    shell.BackgroundTransparency = 0.2
    shell.BorderSizePixel = 0
    shell.ClipsDescendants = true
    mkCorner(shell, 8)
    local str = mkStroke(shell, C.border, 0.5, 0.8)

    local headerFrame = Instance.new("Frame", shell)
    headerFrame.Size = UDim2.new(1, 0, 0, HEADER_H)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundTransparency = 1
    headerFrame.BorderSizePixel = 0
    headerFrame.ZIndex = 5

    local btn = Instance.new("TextButton", headerFrame)
    btn.Size = UDim2.new(1, withDot and -46 or -28, 1, 0)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextColor3 = C.text
    btn.ZIndex = 6

    local dot
    if withDot then
        dot = Instance.new("Frame", headerFrame)
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(1, -36, 0.5, -5)
        dot.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        dot.BorderSizePixel = 0
        dot.ZIndex = 6
        mkCorner(dot, 5)
        mkStroke(dot, C.accent, 0.5, 0.1)
    end

    local arr = Instance.new("TextLabel", headerFrame)
    arr.Size = UDim2.new(0, 20, 0, HEADER_H)
    arr.Position = UDim2.new(1, -22, 0, 0)
    arr.BackgroundTransparency = 1
    arr.Font = Enum.Font.Gotham
    arr.Text = "<"
    arr.TextSize = 9
    arr.TextColor3 = C.textDim
    arr.ZIndex = 6

    shell.MouseEnter:Connect(function()
        TweenService:Create(shell, TF, {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(str, TF, {Transparency = 0.4}):Play()
    end)
    shell.MouseLeave:Connect(function()
        TweenService:Create(shell, TF, {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(str, TF, {Transparency = 0.8}):Play()
    end)

    return shell, btn, arr, str, dot
end

local function applyShellSize(shell, isOpen, getH)
    local targetH = HEADER_H
    if isOpen then
        targetH = HEADER_H + SEP_H + 1 + getH()
    end
    TweenService:Create(shell, TM, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
end

function UI.Button(parent, text, callback)
    local shell, btn, _, str = makeShell(parent, false)
    btn.Text = "  " .. text
    btn.Size = UDim2.new(1, 0, 1, 0)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return shell
end

function UI.FunctionNT(parent, text, items)
    local isOpen = false
    local shell, btn, arr, str = makeShell(parent, false)
    btn.Text = "  " .. text

    local cont, sep, getH = buildContainer(shell, items, HEADER_H, function(newContH)
        if isOpen then
            applyShellSize(shell, true, getH)
        end
    end)

    local function toggle()
        isOpen = not isOpen
        sep.Visible = isOpen
        cont.Visible = isOpen
        applyShellSize(shell, isOpen, getH)
        TweenService:Create(arr, TF, {Rotation = isOpen and 180 or 0}):Play()
    end

    btn.MouseButton1Click:Connect(toggle)
    btn.MouseButton2Click:Connect(toggle)
    return shell
end

function UI.FunctionT(parent, text, items, settings)
    local isOn      = false
    local panelOpen = false
    local settOpen  = false
    local shell, btn, arr, str, dot = makeShell(parent, true)
    btn.Text = "  " .. text

    local hasPanelItems = type(items) == "table" and items[1] ~= nil
    local hasSettings   = type(settings) == "table" and settings[1] ~= nil
    local cont, sep, getH
    local settCont, settSep, getSettH
    if hasPanelItems then
        cont, sep, getH = buildContainer(shell, items, HEADER_H, function()
            if panelOpen then applyShellSize(shell, true, getH) end
        end)
    end

    if hasSettings then
        settCont, settSep, getSettH = buildContainer(shell, settings, HEADER_H, function()
            if settOpen then applyShellSize(shell, true, getSettH) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        TweenService:Create(dot, TF, {
            BackgroundColor3 = isOn and C.accent or Color3.fromRGB(55, 55, 55)
        }):Play()
    end)

    btn.MouseButton2Click:Connect(function()
        if panelOpen then
            panelOpen = false
            sep.Visible = false
            cont.Visible = false
            TweenService:Create(arr, TF, {Rotation = 0}):Play()
            applyShellSize(shell, false, getH)

        elseif settOpen then
            settOpen = false
            settSep.Visible = false
            settCont.Visible = false
            TweenService:Create(arr, TF, {Rotation = 0}):Play()
            applyShellSize(shell, false, getSettH)

        else
            if hasPanelItems then
                panelOpen = true
                sep.Visible = true
                cont.Visible = true
                TweenService:Create(arr, TF, {Rotation = 180}):Play()
                applyShellSize(shell, true, getH)
            elseif hasSettings then
                settOpen = true
                settSep.Visible = true
                settCont.Visible = true
                TweenService:Create(arr, TF, {Rotation = 180}):Play()
                applyShellSize(shell, true, getSettH)
            end
        end
    end)

    return shell
end

function UI.Dropdown(parent, text, options, onSelect)
    local isOpen   = false
    local selected = nil

    local itemsH = PAD_Y_T + PAD_Y_B
    for i = 1, #options do
        itemsH = itemsH + ITEM_H + (i < #options and GAP or 0)
    end

    local shell, btn, arr, str = makeShell(parent, false)

    local function updateLabel()
        btn.Text = selected and ("  " .. text .. "  |  " .. selected) or ("  " .. text)
    end
    updateLabel()

    local sep = Instance.new("Frame", shell)
    sep.Size = UDim2.new(1, -PAD_X * 2, 0, SEP_H)
    sep.Position = UDim2.new(0, PAD_X, 0, HEADER_H)
    sep.BackgroundColor3 = C.sep
    sep.BackgroundTransparency = 0.82
    sep.BorderSizePixel = 0
    sep.Visible = false

    local cont = Instance.new("Frame", shell)
    cont.Position = UDim2.new(0, 0, 0, HEADER_H + SEP_H + 1)
    cont.Size = UDim2.new(1, 0, 0, itemsH)
    cont.BackgroundTransparency = 1
    cont.BorderSizePixel = 0
    cont.Visible = false

    local uipad = Instance.new("UIPadding", cont)
    uipad.PaddingLeft   = UDim.new(0, PAD_X)
    uipad.PaddingRight  = UDim.new(0, PAD_X)
    uipad.PaddingTop    = UDim.new(0, PAD_Y_T)
    uipad.PaddingBottom = UDim.new(0, PAD_Y_B)
    mkList(cont, GAP)

    for _, opt in ipairs(options) do
        mkInnerBtn(cont, opt, 12, ITEM_H, C.innerBg, function()
            selected = opt
            updateLabel()
            isOpen = false
            sep.Visible = false
            cont.Visible = false
            TweenService:Create(arr, TF, {Rotation = 0}):Play()
            TweenService:Create(shell, TM, {Size = UDim2.new(1, 0, 0, HEADER_H)}):Play()
            if onSelect then onSelect(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        sep.Visible = isOpen
        cont.Visible = isOpen
        TweenService:Create(arr, TF, {Rotation = isOpen and 180 or 0}):Play()
        TweenService:Create(shell, TM, {
            Size = UDim2.new(1, 0, 0, isOpen and (HEADER_H + SEP_H + 1 + itemsH) or HEADER_H)
        }):Play()
    end)

    return shell
end
return UI
