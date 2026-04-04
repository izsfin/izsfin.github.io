return function()

    local Players     = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local CoreGui     = game:GetService("CoreGui")
    local UIS         = game:GetService("UserInputService")

    local AccessType = getgenv().DC_AccessType or "Default"
    local CheckURL   = getgenv().DC_CheckURL
    local AntiDC     = getgenv()["antiDCv1FS"]
    local Icons      = getgenv().DC_Icons or {}

    -- Скрываем стандартную консоль
    local DevConsole = CoreGui:FindFirstChild("DevConsoleMaster")
    if DevConsole then DevConsole.Enabled = false end

    local Tabs      = {}
    local ActiveTab = nil

    -- // ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DebugConsole_DC"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    -- // Окно
    local WIN_W, WIN_H = 702, 500
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, WIN_W, 0, WIN_H)
    Window.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
    Window.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Window.BackgroundTransparency = 0.45
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 10)
    WindowCorner.Parent = Window

    -- // Топбар (Watermark полоска)
    local TOPBAR_H = 36
    local TopBar = Instance.new("Frame")
    TopBar.Name = "Watermark"
    TopBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
    TopBar.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Window

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar

    -- Фикс нижних углов
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 10)
    TopBarFix.Position = UDim2.new(0, 0, 1, -10)
    TopBarFix.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Parent = TopBar

    -- // Кнопка + (CreateTab)
    local AddBtn = Instance.new("TextButton")
    AddBtn.Name = "CreateTabButton"
    AddBtn.Size = UDim2.new(0, 26, 0, 26)
    AddBtn.Position = UDim2.new(0, 5, 0.5, -13)
    AddBtn.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    AddBtn.Text = "+"
    AddBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    AddBtn.TextSize = 16
    AddBtn.Font = Enum.Font.GothamBold
    AddBtn.BorderSizePixel = 0
    AddBtn.Parent = TopBar

    local AddCorner = Instance.new("UICorner")
    AddCorner.CornerRadius = UDim.new(0, 5)
    AddCorner.Parent = AddBtn

    -- // Separator
    local Sep = Instance.new("Frame")
    Sep.Name = "Separator"
    Sep.Size = UDim2.new(0, 1, 0, 20)
    Sep.Position = UDim2.new(0, 35, 0.5, -10)
    Sep.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    Sep.BorderSizePixel = 0
    Sep.Parent = TopBar

    -- // Контейнер табов
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -230, 1, 0)
    TabContainer.Position = UDim2.new(0, 40, 0, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ClipsDescendants = true
    TabContainer.Parent = TopBar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.Parent = TabContainer

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingLeft = UDim.new(0, 4)
    TabPadding.Parent = TabContainer

    -- // Правые кнопки
    local RightFrame = Instance.new("Frame")
    RightFrame.Size = UDim2.new(0, 185, 1, 0)
    RightFrame.Position = UDim2.new(1, -188, 0, 0)
    RightFrame.BackgroundTransparency = 1
    RightFrame.Parent = TopBar

    local RightLayout = Instance.new("UIListLayout")
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RightLayout.Padding = UDim.new(0, 4)
    RightLayout.Parent = RightFrame

    local RightPadding = Instance.new("UIPadding")
    RightPadding.PaddingRight = UDim.new(0, 6)
    RightPadding.Parent = RightFrame

    local function makeBtn(text, w, bg)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, w, 0, 24)
        btn.BackgroundColor3 = bg
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = RightFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = btn
        return btn
    end

    local ConsoleBtn  = makeBtn("Console", 70, Color3.fromRGB(65, 65, 65))
    local HideBtn     = makeBtn("−", 26, Color3.fromRGB(65, 65, 65))
    local CloseBtn    = makeBtn("X", 26, Color3.fromRGB(170, 45, 45))

    -- // ShowDebugContainer (основная область)
    local BOTTOM_H = 44
    local DebugContainer = Instance.new("Frame")
    DebugContainer.Name = "ShowDebugContainer"
    DebugContainer.Size = UDim2.new(1, -12, 1, -(TOPBAR_H + BOTTOM_H + 6))
    DebugContainer.Position = UDim2.new(0, 6, 0, TOPBAR_H + 4)
    DebugContainer.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
    DebugContainer.BackgroundTransparency = 0.45
    DebugContainer.BorderSizePixel = 0
    DebugContainer.Parent = Window

    local DebugCorner = Instance.new("UICorner")
    DebugCorner.CornerRadius = UDim.new(0, 8)
    DebugCorner.Parent = DebugContainer

    -- // ShowDebugFrame (скроллинг логов)
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Name = "ShowDebugFrame"
    LogFrame.Size = UDim2.new(1, -4, 1, -4)
    LogFrame.Position = UDim2.new(0, 2, 0, 2)
    LogFrame.BackgroundTransparency = 1
    LogFrame.BorderSizePixel = 0
    LogFrame.ScrollBarThickness = 3
    LogFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogFrame.Parent = DebugContainer

    local LogLayout = Instance.new("UIListLayout")
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.Parent = LogFrame

    local LogPadding = Instance.new("UIPadding")
    LogPadding.PaddingLeft = UDim.new(0, 6)
    LogPadding.PaddingTop = UDim.new(0, 4)
    LogPadding.Parent = LogFrame

    -- // Нижняя панель
    local BottomBar = Instance.new("Frame")
    BottomBar.Name = "BottomBar"
    BottomBar.Size = UDim2.new(1, 0, 0, BOTTOM_H)
    BottomBar.Position = UDim2.new(0, 0, 1, -BOTTOM_H)
    BottomBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BottomBar.BorderSizePixel = 0
    BottomBar.Parent = Window

    local BottomCorner = Instance.new("UICorner")
    BottomCorner.CornerRadius = UDim.new(0, 10)
    BottomCorner.Parent = BottomBar

    local BottomFix = Instance.new("Frame")
    BottomFix.Size = UDim2.new(1, 0, 0, 10)
    BottomFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BottomFix.BorderSizePixel = 0
    BottomFix.Parent = BottomBar

    -- // InputCode
    local InputBg = Instance.new("Frame")
    InputBg.Name = "InputCode"
    InputBg.Size = UDim2.new(1, -120, 0, 28)
    InputBg.Position = UDim2.new(0, 8, 0.5, -14)
    InputBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    InputBg.BorderSizePixel = 0
    InputBg.Parent = BottomBar

    local InputBgCorner = Instance.new("UICorner")
    InputBgCorner.CornerRadius = UDim.new(0, 5)
    InputBgCorner.Parent = InputBg

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -8, 1, 0)
    Input.Position = UDim2.new(0, 6, 0, 0)
    Input.BackgroundTransparency = 1
    Input.TextColor3 = Color3.fromRGB(220, 220, 220)
    Input.PlaceholderText = "Write code to debug..."
    Input.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
    Input.TextSize = 13
    Input.Font = Enum.Font.Code
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.ClearTextOnFocus = false
    Input.MultiLine = false
    Input.Text = ""
    Input.Parent = InputBg

    -- // Run кнопка
    local RunBtn = Instance.new("TextButton")
    RunBtn.Size = UDim2.new(0, 48, 0, 28)
    RunBtn.Position = UDim2.new(1, -108, 0.5, -14)
    RunBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 60)
    RunBtn.Text = "Run"
    RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RunBtn.TextSize = 13
    RunBtn.Font = Enum.Font.GothamBold
    RunBtn.BorderSizePixel = 0
    RunBtn.Parent = BottomBar

    local RunCorner = Instance.new("UICorner")
    RunCorner.CornerRadius = UDim.new(0, 5)
    RunCorner.Parent = RunBtn

    -- // Clear кнопка
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0, 48, 0, 28)
    ClearBtn.Position = UDim2.new(1, -56, 0.5, -14)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(110, 45, 45)
    ClearBtn.Text = "Clear"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.TextSize = 13
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.BorderSizePixel = 0
    ClearBtn.Parent = BottomBar

    local ClearCorner = Instance.new("UICorner")
    ClearCorner.CornerRadius = UDim.new(0, 5)
    ClearCorner.Parent = ClearBtn

    -- // ResizeButton (снизу слева)
    local ResizeBtn = Instance.new("TextButton")
    ResizeBtn.Name = "ResizeButton"
    ResizeBtn.Size = UDim2.new(0, 16, 0, 16)
    ResizeBtn.Position = UDim2.new(0, 2, 1, -18)
    ResizeBtn.BackgroundTransparency = 1
    ResizeBtn.Text = "⌞"
    ResizeBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    ResizeBtn.TextSize = 14
    ResizeBtn.Font = Enum.Font.GothamBold
    ResizeBtn.BorderSizePixel = 0
    ResizeBtn.Parent = Window

    -- // Логика
    local tabCount = 0

    local function parseURL(code)
        return code:match('HttpGet%("([^"]+)"%)') or code:match("HttpGet%('([^']+)'%)")
    end

    local function addLog(tab, text, logType)
        local colorMap = {
            print  = Color3.fromRGB(255, 255, 255),
            warn   = Color3.fromRGB(255, 200, 0),
            error  = Color3.fromRGB(255, 80, 80),
            system = Color3.fromRGB(130, 130, 130),
            urlda  = Color3.fromRGB(255, 100, 100),
        }
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -8, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.BackgroundTransparency = 1
        label.TextColor3 = colorMap[logType] or colorMap.print
        label.TextSize = 13
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Text = text
        label.LayoutOrder = #tab.logs + 1
        label.Parent = tab.logFrame
        table.insert(tab.logs, label)
        task.defer(function()
            tab.logFrame.CanvasPosition = Vector2.new(0, tab.logFrame.AbsoluteCanvasSize.Y)
        end)
    end

    local function setActiveTab(tab)
        if ActiveTab then
            ActiveTab.logFrame.Visible = false
            ActiveTab.btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        ActiveTab = tab
        tab.logFrame.Visible = true
        tab.btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end

    local function createTab()
        tabCount += 1
        local tabName = "Tab " .. tabCount

        -- Кнопка таба
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 84, 0, 26)
        tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabBtn.BorderSizePixel = 0
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.TextSize = 12
        tabBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
        tabBtn.Text = tabName .. "  ×"
        tabBtn.Parent = TabContainer

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 5)
        tabCorner.Parent = tabBtn

        -- Лог фрейм для таба
        local logFrame = Instance.new("ScrollingFrame")
        logFrame.Size = UDim2.new(1, -4, 1, -4)
        logFrame.Position = UDim2.new(0, 2, 0, 2)
        logFrame.BackgroundTransparency = 1
        logFrame.BorderSizePixel = 0
        logFrame.ScrollBarThickness = 3
        logFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
        logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        logFrame.Visible = false
        logFrame.Parent = DebugContainer

        local ll = Instance.new("UIListLayout")
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Padding = UDim.new(0, 2)
        ll.Parent = logFrame

        local lp = Instance.new("UIPadding")
        lp.PaddingLeft = UDim.new(0, 6)
        lp.PaddingTop = UDim.new(0, 4)
        lp.Parent = logFrame

        local tab = { name = tabName, btn = tabBtn, logFrame = logFrame, logs = {} }

        tabBtn.MouseButton1Click:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local relX = mouse.X - tabBtn.AbsolutePosition.X
            if relX > tabBtn.AbsoluteSize.X - 18 then
                logFrame:Destroy()
                tabBtn:Destroy()
                for i, t in ipairs(Tabs) do
                    if t == tab then table.remove(Tabs, i) break end
                end
                if ActiveTab == tab then
                    ActiveTab = nil
                    if #Tabs > 0 then setActiveTab(Tabs[#Tabs]) end
                end
            else
                setActiveTab(tab)
            end
        end)

        table.insert(Tabs, tab)
        setActiveTab(tab)
        return tab
    end

    local function runScript(code)
        if not ActiveTab then return end
        local tab = ActiveTab
        local url = parseURL(code)

        if url and CheckURL then
            local blocked, msg = CheckURL(url)
            if blocked then addLog(tab, msg, "urlda") return end
        end

        if AntiDC then
            local blocked = AntiDC:CheckCode(code)
            if blocked then addLog(tab, "[DC] Script has AntiDebugConsole protection.", "error") return end
        end

        task.spawn(function()
            if url then
                local startTime = tick()
                addLog(tab, "Loading code from " .. url .. "...", "system")
            end

            local fn, compileErr = loadstring(code)
            if not fn then
                addLog(tab, "Compile error: " .. tostring(compileErr), "error")
                return
            end

            local env = getfenv(fn)
            env.print = function(...)
                local parts = {}
                for _, v in ipairs({...}) do table.insert(parts, tostring(v)) end
                addLog(tab, table.concat(parts, "\t"), "print")
            end
            env.warn = function(...)
                local parts = {}
                for _, v in ipairs({...}) do table.insert(parts, tostring(v)) end
                addLog(tab, table.concat(parts, "\t"), "warn")
            end

            if url then
                local elapsed = math.floor((tick() - 0) * 10) / 10
                addLog(tab, "Loaded | " .. elapsed .. "s", "system")
            end

            local ok, err = pcall(fn)
            if not ok then addLog(tab, tostring(err), "error") end
        end)
    end

    -- // Console режим
    local consoleMode = false
    local function enableConsoleMode()
        consoleMode = true
        if not ActiveTab then createTab() end
        addLog(ActiveTab, "[Console] Mirroring output...", "system")
        game:GetService("LogService").MessageOut:Connect(function(msg, msgType)
            if not consoleMode or not ActiveTab then return end
            local t = "print"
            if msgType == Enum.MessageType.MessageWarning then t = "warn"
            elseif msgType == Enum.MessageType.MessageError then t = "error" end
            addLog(ActiveTab, msg, t)
        end)
    end

    -- // Кнопки
    AddBtn.MouseButton1Click:Connect(createTab)

    RunBtn.MouseButton1Click:Connect(function()
        if Input.Text == "" then return end
        runScript(Input.Text)
    end)

    ClearBtn.MouseButton1Click:Connect(function()
        if not ActiveTab then return end
        for _, l in ipairs(ActiveTab.logs) do l:Destroy() end
        ActiveTab.logs = {}
    end)

    ConsoleBtn.MouseButton1Click:Connect(function()
        if not consoleMode then
            enableConsoleMode()
            ConsoleBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 45)
        else
            consoleMode = false
            ConsoleBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        end
    end)

    HideBtn.MouseButton1Click:Connect(function()
        Window.Visible = not Window.Visible
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        if DevConsole then DevConsole.Enabled = true end
    end)

    -- // Drag
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- // Resize
    local resizing, resizeStart, startSize
    ResizeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = Window.Size
        end
    end)
    ResizeBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newW = math.max(400, startSize.X.Offset + delta.X)
            local newH = math.max(300, startSize.Y.Offset + delta.Y)
            Window.Size = UDim2.new(0, newW, 0, newH)
        end
    end)

    -- // F9
    UIS.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.F9 then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    createTab()

    return { createTab = createTab, addLog = addLog }
end