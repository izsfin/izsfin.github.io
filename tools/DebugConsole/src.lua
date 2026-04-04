-- // DebugConsole.lua
return function()

    local Players      = game:GetService("Players")
    local LocalPlayer  = Players.LocalPlayer
    local CoreGui      = game:GetService("CoreGui")

    local AccessType   = getgenv().DC_AccessType or "Default"
    local CheckURL     = getgenv().DC_CheckURL
    local AntiDC       = getgenv()["antiDC" .. "v1" .. "FS"]
    local Colors       = getgenv().DC_Colors
    local Icons        = getgenv().DC_Icons

    -- // Скрываем стандартную консоль
    local DevConsole = CoreGui:FindFirstChild("DevConsoleMaster")
    if DevConsole then
        DevConsole.Enabled = false
    end

    -- // Состояние
    local Tabs = {}
    local ActiveTab = nil

    -- // Создаём ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DebugConsole_DC"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    -- // Главное окно
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.new(0, 710, 0, 430)
    Window.Position = UDim2.new(0.5, -355, 0.5, -215)
    Window.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Window.BorderSizePixel = 0
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 6)
    WindowCorner.Parent = Window

    -- // Топбар
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Window

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 6)
    TopCorner.Parent = TopBar

    -- Фикс нижних углов топбара
    local TopFix = Instance.new("Frame")
    TopFix.Size = UDim2.new(1, 0, 0, 6)
    TopFix.Position = UDim2.new(0, 0, 1, -6)
    TopFix.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    TopFix.BorderSizePixel = 0
    TopFix.Parent = TopBar

    -- // Кнопка добавить таб
    local AddTabBtn = Instance.new("TextButton")
    AddTabBtn.Name = "AddTab"
    AddTabBtn.Size = UDim2.new(0, 24, 0, 24)
    AddTabBtn.Position = UDim2.new(0, 4, 0, 4)
    AddTabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    AddTabBtn.Text = "+"
    AddTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AddTabBtn.TextSize = 16
    AddTabBtn.BorderSizePixel = 0
    AddTabBtn.Font = Enum.Font.GothamBold
    AddTabBtn.Parent = TopBar

    local AddCorner = Instance.new("UICorner")
    AddCorner.CornerRadius = UDim.new(0, 4)
    AddCorner.Parent = AddTabBtn

    -- // Контейнер табов
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -200, 1, 0)
    TabContainer.Position = UDim2.new(0, 32, 0, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = TopBar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.Parent = TabContainer

    -- // Кнопки справа (Console / Minimize / Close)
    local RightButtons = Instance.new("Frame")
    RightButtons.Size = UDim2.new(0, 190, 1, 0)
    RightButtons.Position = UDim2.new(1, -194, 0, 0)
    RightButtons.BackgroundTransparency = 1
    RightButtons.Parent = TopBar

    local RightLayout = Instance.new("UIListLayout")
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RightLayout.Padding = UDim.new(0, 4)
    RightLayout.Parent = RightButtons

    local function makeTopBtn(text, bgColor)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, text == "Console" and 70 or 28, 0, 24)
        btn.BackgroundColor3 = bgColor
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = RightButtons
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn
        return btn
    end

    local ConsoleBtn  = makeTopBtn("Console", Color3.fromRGB(70, 70, 70))
    local MinimizeBtn = makeTopBtn("−", Color3.fromRGB(70, 70, 70))
    local CloseBtn    = makeTopBtn("X", Color3.fromRGB(180, 50, 50))

    -- // Область логов
    local LogArea = Instance.new("ScrollingFrame")
    LogArea.Name = "LogArea"
    LogArea.Size = UDim2.new(1, -8, 1, -80)
    LogArea.Position = UDim2.new(0, 4, 0, 36)
    LogArea.BackgroundTransparency = 1
    LogArea.BorderSizePixel = 0
    LogArea.ScrollBarThickness = 4
    LogArea.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    LogArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogArea.Parent = Window

    local LogLayout = Instance.new("UIListLayout")
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Padding = UDim.new(0, 2)
    LogLayout.Parent = LogArea

    -- // Нижняя панель
    local BottomBar = Instance.new("Frame")
    BottomBar.Size = UDim2.new(1, 0, 0, 40)
    BottomBar.Position = UDim2.new(0, 0, 1, -40)
    BottomBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    BottomBar.BorderSizePixel = 0
    BottomBar.Parent = Window

    local BottomFix = Instance.new("Frame")
    BottomFix.Size = UDim2.new(1, 0, 0, 6)
    BottomFix.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    BottomFix.BorderSizePixel = 0
    BottomFix.Parent = BottomBar

    -- // Инпут
    local Input = Instance.new("TextBox")
    Input.Name = "Input"
    Input.Size = UDim2.new(1, -120, 0, 28)
    Input.Position = UDim2.new(0, 6, 0, 6)
    Input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Input.BorderSizePixel = 0
    Input.TextColor3 = Color3.fromRGB(220, 220, 220)
    Input.PlaceholderText = "Write code to debug..."
    Input.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    Input.TextSize = 13
    Input.Font = Enum.Font.Code
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.ClearTextOnFocus = false
    Input.MultiLine = true
    Input.Text = ""
    Input.Parent = BottomBar

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 4)
    InputCorner.Parent = Input

    local InputPadding = Instance.new("UIPadding")
    InputPadding.PaddingLeft = UDim.new(0, 6)
    InputPadding.Parent = Input

    -- // Кнопка Run
    local RunBtn = Instance.new("TextButton")
    RunBtn.Size = UDim2.new(0, 50, 0, 28)
    RunBtn.Position = UDim2.new(1, -112, 0, 6)
    RunBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
    RunBtn.Text = "Run"
    RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RunBtn.TextSize = 13
    RunBtn.Font = Enum.Font.GothamBold
    RunBtn.BorderSizePixel = 0
    RunBtn.Parent = BottomBar

    local RunCorner = Instance.new("UICorner")
    RunCorner.CornerRadius = UDim.new(0, 4)
    RunCorner.Parent = RunBtn

    -- // Кнопка Clear
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0, 50, 0, 28)
    ClearBtn.Position = UDim2.new(1, -58, 0, 6)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    ClearBtn.Text = "Clear"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.TextSize = 13
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.BorderSizePixel = 0
    ClearBtn.Parent = BottomBar

    local ClearCorner = Instance.new("UICorner")
    ClearCorner.CornerRadius = UDim.new(0, 4)
    ClearCorner.Parent = ClearBtn

    -- // Логика табов
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
        label.Parent = tab.logArea

        table.insert(tab.logs, label)

        -- Скролл вниз
        task.defer(function()
            tab.logArea.CanvasPosition = Vector2.new(0, tab.logArea.AbsoluteCanvasSize.Y)
        end)
    end

    local function setActiveTab(tab)
        if ActiveTab then
            ActiveTab.logArea.Visible = false
            ActiveTab.button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        end
        ActiveTab = tab
        tab.logArea.Visible = true
        tab.button.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    end

    local function createTab()
        tabCount += 1
        local tabName = "Tab " .. tabCount

        -- Кнопка таба
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 80, 0, 24)
        tabBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        tabBtn.BorderSizePixel = 0
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.TextSize = 12
        tabBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
        tabBtn.Text = tabName .. "  ×"
        tabBtn.Parent = TabContainer

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 4)
        tabCorner.Parent = tabBtn

        -- Область логов для этого таба
        local logArea = Instance.new("ScrollingFrame")
        logArea.Size = UDim2.new(1, -8, 1, -80)
        logArea.Position = UDim2.new(0, 4, 0, 36)
        logArea.BackgroundTransparency = 1
        logArea.BorderSizePixel = 0
        logArea.ScrollBarThickness = 4
        logArea.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
        logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
        logArea.Visible = false
        logArea.Parent = Window

        local logLayout = Instance.new("UIListLayout")
        logLayout.SortOrder = Enum.SortOrder.LayoutOrder
        logLayout.Padding = UDim.new(0, 2)
        logLayout.Parent = logArea

        local tab = {
            name    = tabName,
            button  = tabBtn,
            logArea = logArea,
            logs    = {},
        }

        -- Клик по табу
        tabBtn.MouseButton1Click:Connect(function(x, y)
            -- Проверяем клик по × (правая часть кнопки)
            local relX = x - tabBtn.AbsolutePosition.X
            if relX > tabBtn.AbsoluteSize.X - 18 then
                -- Закрыть таб
                logArea:Destroy()
                tabBtn:Destroy()
                for i, t in ipairs(Tabs) do
                    if t == tab then
                        table.remove(Tabs, i)
                        break
                    end
                end
                if ActiveTab == tab then
                    ActiveTab = nil
                    if #Tabs > 0 then
                        setActiveTab(Tabs[#Tabs])
                    end
                end
            else
                setActiveTab(tab)
            end
        end)

        table.insert(Tabs, tab)
        setActiveTab(tab)
        return tab
    end

    -- // Run логика
    local function runScript(code)
        if not ActiveTab then return end
        local tab = ActiveTab

        -- Ищем URL в коде
        local url = parseURL(code)

        if url and CheckURL then
            local blocked, msg = CheckURL(url)
            if blocked then
                addLog(tab, msg, "urlda")
                return
            end
        end

        -- Проверка AntiDC паттернов
        if AntiDC then
            local blocked, pattern = AntiDC:CheckCode(code)
            if blocked then
                addLog(tab, "[DC] Script has AntiDebugConsole protection.", "error")
                return
            end
        end

        -- Системное сообщение о загрузке
        if url then
            local startTime = tick()
            addLog(tab, "Loading code from " .. url .. "...", "system")
            task.spawn(function()
                local ok, err = pcall(function()
                    local fn, compileErr = loadstring(code)
                    if not fn then
                        addLog(tab, "Compile error: " .. tostring(compileErr), "error")
                        return
                    end

                    -- Перехватываем print/warn/error
                    local env = getfenv(fn)
                    env.print = function(...)
                        local args = {...}
                        local parts = {}
                        for _, v in ipairs(args) do
                            table.insert(parts, tostring(v))
                        end
                        addLog(tab, table.concat(parts, "\t"), "print")
                    end
                    env.warn = function(...)
                        local args = {...}
                        local parts = {}
                        for _, v in ipairs(args) do
                            table.insert(parts, tostring(v))
                        end
                        addLog(tab, table.concat(parts, "\t"), "warn")
                    end

                    local elapsed = math.floor((tick() - startTime) * 10) / 10
                    addLog(tab, "Loaded code from " .. url .. " | " .. elapsed .. "s", "system")

                    fn()
                end)
                if not ok then
                    addLog(tab, tostring(err), "error")
                end
            end)
        else
            -- Обычный код без URL
            task.spawn(function()
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

                local ok, err = pcall(fn)
                if not ok then
                    addLog(tab, tostring(err), "error")
                end
            end)
        end
    end

    -- // Console режим (зеркало стандартного output)
    local consoleMode = false

    local function enableConsoleMode()
        consoleMode = true
        if not ActiveTab then createTab() end
        local tab = ActiveTab
        addLog(tab, "[Console] Mirroring LogService output...", "system")

        local LogService = game:GetService("LogService")
        LogService.MessageOut:Connect(function(msg, msgType)
            if not consoleMode then return end
            local logType = "print"
            if msgType == Enum.MessageType.MessageWarning then
                logType = "warn"
            elseif msgType == Enum.MessageType.MessageError then
                logType = "error"
            end
            if ActiveTab then
                addLog(ActiveTab, msg, logType)
            end
        end)
    end

    -- // Кнопки
    AddTabBtn.MouseButton1Click:Connect(createTab)

    RunBtn.MouseButton1Click:Connect(function()
        local code = Input.Text
        if code == "" then return end
        runScript(code)
    end)

    ClearBtn.MouseButton1Click:Connect(function()
        if not ActiveTab then return end
        for _, label in ipairs(ActiveTab.logs) do
            label:Destroy()
        end
        ActiveTab.logs = {}
    end)

    ConsoleBtn.MouseButton1Click:Connect(function()
        if not consoleMode then
            enableConsoleMode()
            ConsoleBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
        else
            consoleMode = false
            ConsoleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        end
    end)

    MinimizeBtn.MouseButton1Click:Connect(function()
        Window.Visible = not Window.Visible
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        -- Возвращаем стандартную консоль
        if DevConsole then
            DevConsole.Enabled = true
        end
    end)

    -- // Драг окна
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
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- // Стартуем с одним табом
    createTab()

    return {
        createTab = createTab,
        addLog    = addLog,
    }
end