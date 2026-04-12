-- mewixUI | Lightweight Roblox UI Library
-- Usage: local UI = loadstring(...)()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local UI = {}
UI.__index = UI

-- ============================================================
-- THEME
-- ============================================================
local T = {
    bg        = Color3.fromRGB(18, 18, 22),
    bgRow     = Color3.fromRGB(26, 26, 32),
    titleBar  = Color3.fromRGB(24, 24, 30),
    stroke    = Color3.fromRGB(60, 60, 75),
    textPrim  = Color3.fromRGB(220, 220, 230),
    textSec   = Color3.fromRGB(190, 190, 200),
    textMute  = Color3.fromRGB(100, 100, 120),
    textVal   = Color3.fromRGB(130, 130, 150),
    accent    = Color3.fromRGB(100, 140, 255),
    togOn     = Color3.fromRGB(100, 180, 100),
    togOff    = Color3.fromRGB(55, 55, 65),
    trackBg   = Color3.fromRGB(45, 45, 55),
    dropBg    = Color3.fromRGB(36, 36, 46),
    close     = Color3.fromRGB(200, 60, 60),
    inputBg   = Color3.fromRGB(30, 30, 38),
}

-- ============================================================
-- HELPERS
-- ============================================================
local function corner(parent, rad)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, rad or 6)
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or T.stroke
    s.Thickness = thickness or 1
    return s
end

local function label(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Font = props.font or Enum.Font.Gotham
    l.TextSize = props.size or 12
    l.TextColor3 = props.color or T.textSec
    l.Text = props.text or ""
    l.Size = props.sz or UDim2.new(1, 0, 1, 0)
    l.Position = props.pos or UDim2.new(0, 0, 0, 0)
    l.TextXAlignment = props.align or Enum.TextXAlignment.Left
    return l
end

-- ============================================================
-- WINDOW
-- ============================================================
function UI.new(opts)
    opts = opts or {}
    local title   = opts.Title   or "UI"
    local keybind = opts.Keybind or "Insert"

    -- cleanup old
    local existing = CoreGui:FindFirstChild("mewixUI_" .. title)
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "mewixUI_" .. title
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local main = Instance.new("Frame", gui)
    main.Name = "Main"
    main.Size = UDim2.new(0, 280, 0, 46) -- растёт по контенту
    main.Position = UDim2.new(0.5, -140, 0.5, -165)
    main.BackgroundColor3 = T.bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    corner(main, 8)
    stroke(main, T.stroke, 1)

    -- title bar
    local bar = Instance.new("Frame", main)
    bar.Size = UDim2.new(1, 0, 0, 36)
    bar.BackgroundColor3 = T.titleBar
    bar.BorderSizePixel = 0
    corner(bar, 8)
    local barFix = Instance.new("Frame", bar)
    barFix.Size = UDim2.new(1, 0, 0, 10)
    barFix.Position = UDim2.new(0, 0, 1, -10)
    barFix.BackgroundColor3 = T.titleBar
    barFix.BorderSizePixel = 0

    -- icon
    local xOff = 10
    if opts.Icon then
        local ico = Instance.new("ImageLabel", bar)
        ico.Size = UDim2.new(0, 18, 0, 18)
        ico.Position = UDim2.new(0, 10, 0.5, -9)
        ico.BackgroundTransparency = 1
        ico.Image = tostring(opts.Icon):find("rbxassetid") and opts.Icon or "rbxassetid://" .. opts.Icon
        xOff = 32
    end

    label(bar, {
        text  = title,
        sz    = UDim2.new(1, -44, 1, 0),
        pos   = UDim2.new(0, xOff, 0, 0),
        color = T.textPrim,
        font  = Enum.Font.GothamMedium,
        size  = 13,
    })

    local closeBtn = Instance.new("TextButton", bar)
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -30, 0, 6)
    closeBtn.BackgroundColor3 = T.close
    closeBtn.Text = ""
    closeBtn.BorderSizePixel = 0
    corner(closeBtn, 6)
    label(closeBtn, { text = "×", size = 16, font = Enum.Font.GothamBold, color = Color3.new(1,1,1) })
    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    -- content scroll
    local content = Instance.new("Frame", main)
    content.Name = "Content"
    content.Position = UDim2.new(0, 10, 0, 40)
    content.Size = UDim2.new(1, -20, 0, 0)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)

    -- авторазмер окна
    local pad = Instance.new("UIPadding", content)
    pad.PaddingBottom = UDim.new(0, 8)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        main.Size = UDim2.new(0, 280, 0, layout.AbsoluteContentSize.Y + 40 + 8 + 5)
    end)

    -- keybind
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        local ok, key = pcall(function() return Enum.KeyCode[keybind] end)
        if ok and inp.KeyCode == key then
            main.Visible = not main.Visible
        end
    end)

    -- window object
    local win = { _content = content, _order = 0, _gui = gui }

    function win:_nextOrder()
        self._order += 1
        return self._order
    end

    -- --------------------------------------------------------
    -- SECTION
    -- --------------------------------------------------------
    function win:Section(name)
        local order = self:_nextOrder()

        local lbl = Instance.new("TextLabel", content)
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = T.textMute
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = order

        local sec = { _win = self }

        -- ----------------------------------------------------
        -- TOGGLE
        -- ----------------------------------------------------
        function sec:Toggle(labelText, default, onChange)
            local o = self._win:_nextOrder()
            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = T.bgRow
            row.BorderSizePixel = 0
            row.LayoutOrder = o
            corner(row)

            label(row, {
                text = labelText,
                sz   = UDim2.new(1, -50, 1, 0),
                pos  = UDim2.new(0, 10, 0, 0),
            })

            local bg = Instance.new("Frame", row)
            bg.Size = UDim2.new(0, 34, 0, 18)
            bg.Position = UDim2.new(1, -42, 0.5, -9)
            bg.BorderSizePixel = 0
            corner(bg, 9)

            local knob = Instance.new("Frame", bg)
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.BackgroundColor3 = Color3.new(1,1,1)
            knob.BorderSizePixel = 0
            corner(knob, 7)

            local val = default or false
            local api = {}

            function api.Set(v, silent)
                val = v
                local bgC = v and T.togOn or T.togOff
                local kP  = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
                if silent then
                    bg.BackgroundColor3 = bgC
                    knob.Position = kP
                else
                    TweenService:Create(bg,   TweenInfo.new(0.15), {BackgroundColor3 = bgC}):Play()
                    TweenService:Create(knob, TweenInfo.new(0.15), {Position = kP}):Play()
                    if onChange then onChange(v) end
                end
            end

            api.Set(val, true)

            local btn = Instance.new("TextButton", row)
            btn.Size = UDim2.new(1,0,1,0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.MouseButton1Click:Connect(function() api.Set(not val) end)

            return api
        end

        -- ----------------------------------------------------
        -- SLIDER
        -- ----------------------------------------------------
        function sec:Slider(labelText, min, max, default, increment, onChange)
            local o = self._win:_nextOrder()
            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 42)
            row.BackgroundColor3 = T.bgRow
            row.BorderSizePixel = 0
            row.LayoutOrder = o
            corner(row)

            local hdr = Instance.new("Frame", row)
            hdr.Size = UDim2.new(1, 0, 0, 20)
            hdr.BackgroundTransparency = 1

            label(hdr, {
                text = labelText,
                sz   = UDim2.new(1,-40,1,0),
                pos  = UDim2.new(0,10,0,0),
            })

            local valLbl = label(hdr, {
                sz    = UDim2.new(0,36,1,0),
                pos   = UDim2.new(1,-42,0,0),
                color = T.textVal,
                size  = 11,
                font  = Enum.Font.GothamMedium,
                align = Enum.TextXAlignment.Right,
            })

            local track = Instance.new("Frame", row)
            track.Size = UDim2.new(1,-20,0,4)
            track.Position = UDim2.new(0,10,0,28)
            track.BackgroundColor3 = T.trackBg
            track.BorderSizePixel = 0
            corner(track, 2)

            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new(0,0,1,0)
            fill.BackgroundColor3 = T.accent
            fill.BorderSizePixel = 0
            corner(fill, 2)

            local dotpart = tostring(increment):match("%.(%d+)")
            local decimals = dotpart and #dotpart or 0
            local fmt = "%." .. decimals .. "f"
            local cur = default or min

            local function setValue(v)
                cur = math.clamp(v, min, max)
                cur = tonumber(string.format(fmt, math.round(cur / increment) * increment))
                fill.Size = UDim2.new((cur - min) / (max - min), 0, 1, 0)
                valLbl.Text = string.format(fmt, cur)
                if onChange then onChange(cur) end
            end
            setValue(cur)

            local dragging = false
            local tb = Instance.new("TextButton", track)
            tb.Size = UDim2.new(1,0,0,14)
            tb.Position = UDim2.new(0,0,0.5,-7)
            tb.BackgroundTransparency = 1
            tb.Text = ""
            tb.MouseButton1Down:Connect(function() dragging = true end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local a = track.AbsolutePosition
                    setValue(min + (max-min) * math.clamp((i.Position.X - a.X) / track.AbsoluteSize.X, 0, 1))
                end
            end)
        end

        -- ----------------------------------------------------
        -- DROPDOWN
        -- ----------------------------------------------------
        function sec:Dropdown(labelText, options, default, onChange)
            local o = self._win:_nextOrder()
            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = T.bgRow
            row.BorderSizePixel = 0
            row.LayoutOrder = o
            row.ClipsDescendants = false
            corner(row)

            label(row, {
                text = labelText,
                sz   = UDim2.new(0.5,0,1,0),
                pos  = UDim2.new(0,10,0,0),
            })

            local selected = default or (options and options[1]) or ""

            local btn = Instance.new("TextButton", row)
            btn.Size = UDim2.new(0.48, 0, 0, 24)
            btn.Position = UDim2.new(0.5, 0, 0.5, -12)
            btn.BackgroundColor3 = T.dropBg
            btn.BorderSizePixel = 0
            btn.Text = selected
            btn.TextColor3 = T.textPrim
            btn.TextSize = 11
            btn.Font = Enum.Font.Gotham
            btn.ClipsDescendants = true
            corner(btn, 5)
            
            local list = Instance.new("Frame", gui)
            list.BackgroundColor3 = T.titleBar
            list.BorderSizePixel = 0
            list.Visible = false
            list.ZIndex = 20
            corner(list, 6)
            stroke(list, T.stroke, 1)
            local ll = Instance.new("UIListLayout", list)
            ll.SortOrder = Enum.SortOrder.LayoutOrder

            local api = {}

            function api.Refresh(opts)
                options = opts
                for _, c in pairs(list:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for i, opt in ipairs(opts) do
                    local ob = Instance.new("TextButton", list)
                    ob.Size = UDim2.new(1, 0, 0, 26)
                    ob.BackgroundTransparency = 1
                    ob.Text = opt
                    ob.TextColor3 = T.textSec
                    ob.TextSize = 11
                    ob.Font = Enum.Font.Gotham
                    ob.LayoutOrder = i
                    ob.ZIndex = 21
                    ob.MouseEnter:Connect(function()
                        TweenService:Create(ob, TweenInfo.new(0.1), {BackgroundTransparency = 0.7}):Play()
                        ob.BackgroundColor3 = T.accent
                    end)
                    ob.MouseLeave:Connect(function()
                        TweenService:Create(ob, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                    end)
                    ob.MouseButton1Click:Connect(function()
                        selected = opt
                        btn.Text = opt
                        list.Visible = false
                        if onChange then onChange(opt) end
                    end)
                end
                list.Size = UDim2.new(0, btn.AbsoluteSize.X, 0, #opts * 26 + 4)
            end

            api.Refresh(options or {})

            btn.MouseButton1Click:Connect(function()
                if not list.Visible then
                    local abs = btn.AbsolutePosition
                    list.Position = UDim2.new(0, abs.X, 0, abs.Y + btn.AbsoluteSize.Y + 2)
                    list.Size = UDim2.new(0, btn.AbsoluteSize.X, 0, #options * 26 + 4)
                end
                list.Visible = not list.Visible
            end)

            UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    if list.Visible then
                        task.defer(function() list.Visible = false end)
                    end
                end
            end)

            return api
        end

        function sec:TextBox(placeholder, onChange)
            local o = self._win:_nextOrder()
            local row = Instance.new("Frame", content)
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = T.bgRow
            row.BorderSizePixel = 0
            row.LayoutOrder = o
            corner(row)

            local box = Instance.new("TextBox", row)
            box.Size = UDim2.new(1, -16, 0, 24)
            box.Position = UDim2.new(0, 8, 0.5, -12)
            box.BackgroundColor3 = T.inputBg
            box.BorderSizePixel = 0
            box.Text = ""
            box.PlaceholderText = placeholder or ""
            box.PlaceholderColor3 = T.textMute
            box.TextColor3 = T.textSec
            box.TextSize = 12
            box.Font = Enum.Font.Gotham
            box.ClearTextOnFocus = false
            corner(box, 5)
            stroke(box, T.stroke, 1)

            local pad = Instance.new("UIPadding", box)
            pad.PaddingLeft = UDim.new(0, 8)

            box.FocusLost:Connect(function(enter)
                if onChange then onChange(box.Text, enter) end
            end)

            local api = {}
            function api.Get() return box.Text end
            function api.Set(v) box.Text = v end
            return api
        end

        return sec
    end

    return win
end

return UI