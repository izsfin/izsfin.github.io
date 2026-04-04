return function()
    local Players   = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local CoreGui   = game:GetService("CoreGui")
    local UIS       = game:GetService("UserInputService")

    local CheckURL  = getgenv().DC_CheckURL
    local AntiDC    = getgenv()["antiDCv1FS"]

    local DevConsole = CoreGui:FindFirstChild("DevConsoleMaster")
    if DevConsole then DevConsole.Enabled = false end

    local Tabs      = {}
    local ActiveTab = nil
    local consoleMode = false
    local tabCount  = 0

    -- // ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DebugConsole_DC"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    -- // Window
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Position = UDim2.new(0.255759, 0, 0.231209, 0)
    Window.Size = UDim2.new(0, 1088, 0, 686)
    Window.BackgroundColor3 = Color3.new(0.0705882, 0.0705882, 0.0705882)
    Window.BackgroundTransparency = 0.1
    Window.BorderSizePixel = 0
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.Parent = Window

    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.Thickness = 1.5
    WindowStroke.Parent = Window

    -- // SeparatorFrame
    local SeparatorFrame = Instance.new("Frame")
    SeparatorFrame.Name = "SeparatorFrame"
    SeparatorFrame.Position = UDim2.new(0.223346, 0, 0, 0)
    SeparatorFrame.Size = UDim2.new(0, 2, 0, 686)
    SeparatorFrame.BackgroundColor3 = Color3.new(0.203922, 0.203922, 0.203922)
    SeparatorFrame.BackgroundTransparency = 0.4
    SeparatorFrame.BorderSizePixel = 0
    SeparatorFrame.Parent = Window

    -- // ButtonContainer
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Name = "ButtonContainer"
    ButtonContainer.Position = UDim2.new(0.228, 0, 0.0131195, 0)
    ButtonContainer.Size = UDim2.new(0, 833, 0, 34)
    ButtonContainer.BackgroundColor3 = Color3.new(0.203922, 0.203922, 0.203922)
    ButtonContainer.BackgroundTransparency = 0.4
    ButtonContainer.BorderSizePixel = 0
    ButtonContainer.Parent = Window

    local BCCorner = Instance.new("UICorner")
    BCCorner.CornerRadius = UDim.new(0, 6)
    BCCorner.Parent = ButtonContainer

    -- // ExecuteButton
    local ExecuteButton = Instance.new("TextButton")
    ExecuteButton.Name = "ExecuteButton"
    ExecuteButton.Position = UDim2.new(0, 7, 0, 4)
    ExecuteButton.Size = UDim2.new(0, 136, 0, 26)
    ExecuteButton.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)
    ExecuteButton.BorderSizePixel = 0
    ExecuteButton.Text = "Execute"
    ExecuteButton.TextColor3 = Color3.new(1, 1, 1)
    ExecuteButton.TextSize = 14
    ExecuteButton.Font = Enum.Font.ArialBold
    ExecuteButton.Parent = ButtonContainer

    local ExecCorner = Instance.new("UICorner")
    ExecCorner.CornerRadius = UDim.new(0, 3)
    ExecCorner.Parent = ExecuteButton

    -- // InputCodeBox
    local InputCodeBox = Instance.new("TextBox")
    InputCodeBox.Name = "InputCodeBox"
    InputCodeBox.Position = UDim2.new(0, 150, 0, 4)
    InputCodeBox.Size = UDim2.new(1, -290, 0, 27)
    InputCodeBox.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)
    InputCodeBox.BorderSizePixel = 0
    InputCodeBox.ClipsDescendants = true
    InputCodeBox.Text = ""
    InputCodeBox.TextColor3 = Color3.new(1, 1, 1)
    InputCodeBox.TextSize = 14
    InputCodeBox.Font = Enum.Font.ArialBold
    InputCodeBox.PlaceholderText = "Write code to debug..."
    InputCodeBox.PlaceholderColor3 = Color3.new(0.854902, 0.854902, 0.854902)
    InputCodeBox.ClearTextOnFocus = false
    InputCodeBox.MultiLine = false
    InputCodeBox.Parent = ButtonContainer

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 3)
    InputCorner.Parent = InputCodeBox

    -- // HideButton
    local HideButton = Instance.new("TextButton")
    HideButton.Name = "HideButton"
    HideButton.Position = UDim2.new(1, -58, 0, 4)
    HideButton.Size = UDim2.new(0, 25, 0, 25)
    HideButton.BackgroundColor3 = Color3.new(0.239216, 0.239216, 0.239216)
    HideButton.BorderSizePixel = 0
    HideButton.Text = "—"
    HideButton.TextColor3 = Color3.new(1, 1, 1)
    HideButton.TextSize = 14
    HideButton.Font = Enum.Font.SourceSans
    HideButton.Parent = ButtonContainer

    local HideCorner = Instance.new("UICorner")
    HideCorner.CornerRadius = UDim.new(0, 5)
    HideCorner.Parent = HideButton

    -- // CloseButton
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Position = UDim2.new(1, -30, 0, 4)
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.BackgroundColor3 = Color3.new(0.239216, 0, 0)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.TextSize = 14
    CloseButton.Font = Enum.Font.SourceSans
    CloseButton.Parent = ButtonContainer

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseCorner.Parent = CloseButton

    -- // ShowFrame (лог область)
    local ShowFrame = Instance.new("ScrollingFrame")
    ShowFrame.Name = "ShowFrame"
    ShowFrame.Position = UDim2.new(0.22886, 0, 0.0801749, 0)
    ShowFrame.Size = UDim2.new(0, 833, 0, 624)
    ShowFrame.BackgroundColor3 = Color3.new(0.168627, 0.168627, 0.168627)
    ShowFrame.BackgroundTransparency = 0.4
    ShowFrame.BorderSizePixel = 0
    ShowFrame.ScrollBarThickness = 3
    ShowFrame.ScrollBarImageColor3 = Color3.new(0.4, 0.4, 0.4)
    ShowFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ShowFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ShowFrame.Parent = Window

    local SFCorner = Instance.new("UICorner")
    SFCorner.CornerRadius = UDim.new(0, 15)
    SFCorner.Parent = ShowFrame

    local SFLayout = Instance.new("UIListLayout")
    SFLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SFLayout.Padding = UDim.new(0, 2)
    SFLayout.Parent = ShowFrame

    local SFPadding = Instance.new("UIPadding")
    SFPadding.PaddingLeft = UDim.new(0, 6)
    SFPadding.PaddingTop = UDim.new(0, 4)
    SFPadding.Parent = ShowFrame

    -- // ConsoleFrame
    local ConsoleFrame = Instance.new("Frame")
    ConsoleFrame.Name = "ConsoleFrame"
    ConsoleFrame.Position = UDim2.new(0.00735294, 0, 0.00874636, 0)
    ConsoleFrame.Size = UDim2.new(0, 227, 0, 40)
    ConsoleFrame.BackgroundColor3 = Color3.new(0.168627, 0.168627, 0.168627)
    ConsoleFrame.BackgroundTransparency = 0.4
    ConsoleFrame.BorderSizePixel = 0
    ConsoleFrame.Parent = Window

    local CFCorner = Instance.new("UICorner")
    CFCorner.Parent = ConsoleFrame

    local ConsoleButton = Instance.new("TextButton")
    ConsoleButton.Name = "ConsoleButton"
    ConsoleButton.Position = UDim2.new(0.022, 0, 0.125, 0)
    ConsoleButton.Size = UDim2.new(0, 216, 0, 32)
    ConsoleButton.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)
    ConsoleButton.BorderSizePixel = 0
    ConsoleButton.Text = ""
    ConsoleButton.TextSize = 1
    ConsoleButton.Parent = ConsoleFrame

    local CBCorner = Instance.new("UICorner")
    CBCorner.Parent = ConsoleButton

    local ConsoleLabel = Instance.new("TextLabel")
    ConsoleLabel.Position = UDim2.new(0.351852, 0, 0.108929, 0)
    ConsoleLabel.Size = UDim2.new(0, 65, 0, 22)
    ConsoleLabel.BackgroundTransparency = 1
    ConsoleLabel.Text = "Console"
    ConsoleLabel.TextColor3 = Color3.new(1, 1, 1)
    ConsoleLabel.TextSize = 20
    ConsoleLabel.Font = Enum.Font.SourceSansBold
    ConsoleLabel.Parent = ConsoleButton

    -- // TabFrame
    local TabFrame = Instance.new("Frame")
    TabFrame.Name = "TabFrame"
    TabFrame.Position = UDim2.new(0.00735294, 0, 0.0801749, 0)
    TabFrame.Size = UDim2.new(0, 227, 0, 624)
    TabFrame.BackgroundColor3 = Color3.new(0.168627, 0.168627, 0.168627)
    TabFrame.BackgroundTransparency = 0.4
    TabFrame.BorderSizePixel = 0
    TabFrame.ClipsDescendants = true
    TabFrame.Parent = Window

    local TFCorner = Instance.new("UICorner")
    TFCorner.Parent = TabFrame

    local TFLayout = Instance.new("UIListLayout")
    TFLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TFLayout.Padding = UDim.new(0, 4)
    TFLayout.Parent = TabFrame

    local TFPadding = Instance.new("UIPadding")
    TFPadding.PaddingTop = UDim.new(0, 4)
    TFPadding.PaddingLeft = UDim.new(0, 3)
    TFPadding.PaddingRight = UDim.new(0, 3)
    TFPadding.Parent = TabFrame

    -- // ResizeButton
    local ResizeButton = Instance.new("TextButton")
    ResizeButton.Name = "ResizeButton"
    ResizeButton.Position = UDim2.new(1, -28, 1, -28)
    ResizeButton.Size = UDim2.new(0, 25, 0, 25)
    ResizeButton.BackgroundColor3 = Color3.new(0.545098, 0.545098, 0.545098)
    ResizeButton.BorderSizePixel = 0
    ResizeButton.Text = "⌞"
    ResizeButton.TextColor3 = Color3.new(1, 1, 1)
    ResizeButton.TextSize = 14
    ResizeButton.Font = Enum.Font.SourceSans
    ResizeButton.Parent = Window

    local RBCorner = Instance.new("UICorner")
    RBCorner.CornerRadius = UDim.new(0, 15)
    RBCorner.Parent = ResizeButton

    -- // Контекстное меню
    local ContextMenu = Instance.new("Frame")
    ContextMenu.Name = "ContextMenu"
    ContextMenu.Size = UDim2.new(0, 120, 0, 0)
    ContextMenu.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    ContextMenu.BorderSizePixel = 0
    ContextMenu.Visible = false
    ContextMenu.ZIndex = 10
    ContextMenu.Parent = ScreenGui

    local CMCorner = Instance.new("UICorner")
    CMCorner.CornerRadius = UDim.new(0, 6)
    CMCorner.Parent = ContextMenu

    local CMStroke = Instance.new("UIStroke")
    CMStroke.Thickness = 1
    CMStroke.Color = Color3.new(0.3, 0.3, 0.3)
    CMStroke.Parent = ContextMenu

    local CMLayout = Instance.new("UIListLayout")
    CMLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CMLayout.Padding = UDim.new(0, 1)
    CMLayout.Parent = ContextMenu

    local CMPadding = Instance.new("UIPadding")
    CMPadding.PaddingTop = UDim.new(0, 4)
    CMPadding.PaddingBottom = UDim.new(0, 4)
    CMPadding.Parent = ContextMenu

    local function makeCMBtn(text, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        btn.TextSize = 13
        btn.Font = Enum.Font.SourceSans
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 11
        btn.LayoutOrder = order
        btn.Parent = ContextMenu

        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, 10)
        p.Parent = btn

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        end)

        return btn
    end

    local CM_Close  = makeCMBtn("Close", 1)
    local CM_Clear  = makeCMBtn("Clear", 2)
    local CM_Create = makeCMBtn("Create", 3)

    local cmTarget = nil -- "tab" | "console" | "empty"

    local function showContextMenu(x, y, target)
        cmTarget = target
        CM_Close.Visible  = target == "tab"
        CM_Clear.Visible  = target == "tab" or target == "console"
        CM_Create.Visible = target == "empty"

        local btnCount = 0
        for _, btn in ipairs({CM_Close, CM_Clear, CM_Create}) do
            if btn.Visible then btnCount += 1 end
        end

        ContextMenu.Size = UDim2.new(0, 120, 0, btnCount * 27 + 8)
        ContextMenu.Position = UDim2.new(0, x, 0, y)
        ContextMenu.Visible = true
    end

    local function hideContextMenu()
        ContextMenu.Visible = false
        cmTarget = nil
    end

    -- // Команды
    local function parseCommands(text)
        local commands = {}
        for cmd in text:gmatch("(/[^;]+);") do
            table.insert(commands, cmd:match("^%s*(.-)%s*$"))
        end
        return commands
    end

    local function applyCommand(cmd)
        local name, val = cmd:match("^/(%S+)%s+(.+)$")
        if not name or not val then return false end

        local aliases = {
            bg  = Window,
            tf  = TabFrame,
            sf  = ShowFrame,
            bc  = ButtonContainer,
        }

        -- /set{alias}tr {value}
        local aliasName, prop = name:match("^set(%a+)(tr)$")
        if aliasName and prop == "tr" then
            local obj = aliases[aliasName]
            if obj then
                obj.BackgroundTransparency = tonumber(val) or 0
                return true
            end
        end

        -- /set{alias}img {value}
        aliasName = name:match("^set(%a+)img$")
        if aliasName then
            local obj = aliases[aliasName]
            if obj then
                -- Конвертируем в ImageLabel если нужно
                local imgId = val
                if val:match("^assets%.") then
                    local assetName = val:match("^assets%.(.+)$")
                    local assets = getgenv().assets
                    if assets and assets[assetName] then
                        imgId = assets[assetName]
                    end
                end
                -- Window это Frame — меняем BackgroundColor через ImageLabel overlay
                if obj == Window then
                    local overlay = Window:FindFirstChild("_BgImage")
                    if not overlay then
                        overlay = Instance.new("ImageLabel")
                        overlay.Name = "_BgImage"
                        overlay.Size = UDim2.new(1, 0, 1, 0)
                        overlay.BackgroundTransparency = 1
                        overlay.ZIndex = 0
                        overlay.Parent = Window
                    end
                    overlay.Image = imgId
                else
                    pcall(function() obj.Image = imgId end)
                end
                return true
            end
        end

        return false
    end

    local function processInput(text)
        if text:match("^/") then
            local cmds = parseCommands(text)
            if #cmds > 0 then
                for _, cmd in ipairs(cmds) do
                    applyCommand(cmd)
                end
                return true
            end
        end
        return false
    end

    -- // Логи
    local colorMap = {
        print  = Color3.fromRGB(255, 255, 255),
        warn   = Color3.fromRGB(255, 200, 0),
        error  = Color3.fromRGB(180, 0, 0),
        system = Color3.fromRGB(130, 130, 130),
        urlda  = Color3.fromRGB(255, 100, 100),
    }

    local logCount = 0

    local function addLog(frame, text, logType)
        logCount += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundTransparency = 1
        row.LayoutOrder = logCount
        row.Parent = frame

        local numLbl = Instance.new("TextLabel")
        numLbl.Size = UDim2.new(0, 25, 0, 20)
        numLbl.BackgroundTransparency = 1
        numLbl.Text = tostring(logCount)
        numLbl.TextColor3 = Color3.new(0.462745, 0.462745, 0.462745)
        numLbl.TextSize = 14
        numLbl.Font = Enum.Font.SourceSans
        numLbl.TextXAlignment = Enum.TextXAlignment.Left
        numLbl.Parent = row

        local typeLbl = Instance.new("TextLabel")
        typeLbl.Size = UDim2.new(0, 70, 0, 20)
        typeLbl.Position = UDim2.new(0, 28, 0, 0)
        typeLbl.BackgroundTransparency = 1
        typeLbl.Text = logType == "print" and "" or logType
        typeLbl.TextColor3 = colorMap[logType] or colorMap.print
        typeLbl.TextSize = 14
        typeLbl.Font = Enum.Font.SourceSans
        typeLbl.TextXAlignment = Enum.TextXAlignment.Left
        typeLbl.Parent = row

        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size = UDim2.new(1, -100, 0, 0)
        msgLbl.Position = UDim2.new(0, 100, 0, 0)
        msgLbl.AutomaticSize = Enum.AutomaticSize.Y
        msgLbl.BackgroundTransparency = 1
        msgLbl.Text = text
        msgLbl.TextColor3 = colorMap[logType] or colorMap.print
        msgLbl.TextSize = 14
        msgLbl.Font = Enum.Font.SourceSans
        msgLbl.TextXAlignment = Enum.TextXAlignment.Left
        msgLbl.TextWrapped = true
        msgLbl.Parent = row

        task.defer(function()
            frame.CanvasPosition = Vector2.new(0, frame.AbsoluteCanvasSize.Y)
        end)

        return row
    end

    -- // Консольные логи (отдельный ScrollingFrame)
    local ConsoleLogFrame = Instance.new("ScrollingFrame")
    ConsoleLogFrame.Name = "ConsoleLogFrame"
    ConsoleLogFrame.Size = UDim2.new(1, 0, 1, 0)
    ConsoleLogFrame.BackgroundTransparency = 1
    ConsoleLogFrame.BorderSizePixel = 0
    ConsoleLogFrame.ScrollBarThickness = 3
    ConsoleLogFrame.ScrollBarImageColor3 = Color3.new(0.4, 0.4, 0.4)
    ConsoleLogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ConsoleLogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ConsoleLogFrame.Visible = false
    ConsoleLogFrame.Parent = ShowFrame

    local CLFLayout = Instance.new("UIListLayout")
    CLFLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CLFLayout.Padding = UDim.new(0, 2)
    CLFLayout.Parent = ConsoleLogFrame

    -- // Табы
    local function setActiveTab(tab)
        if ActiveTab then
            ActiveTab.logFrame.Visible = false
            ActiveTab.btn.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)
        end
        ConsoleLogFrame.Visible = false
        consoleMode = false
        ConsoleButton.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)

        ActiveTab = tab
        if tab then
            tab.logFrame.Visible = true
            tab.btn.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
        end
    end

    local function setConsoleActive()
        if ActiveTab then
            ActiveTab.logFrame.Visible = false
            ActiveTab = nil
        end
        ConsoleLogFrame.Visible = true
        consoleMode = true
        ConsoleButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.3)
    end

    local function createTab()
        tabCount += 1
        local tabName = "Tab #" .. tabCount

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -6, 0, 35)
        tabBtn.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = ""
        tabBtn.TextSize = 1
        tabBtn.LayoutOrder = tabCount
        tabBtn.Parent = TabFrame

        local tbCorner = Instance.new("UICorner")
        tbCorner.Parent = tabBtn

        local tbLabel = Instance.new("TextLabel")
        tbLabel.Size = UDim2.new(1, -8, 1, 0)
        tbLabel.Position = UDim2.new(0, 8, 0, 0)
        tbLabel.BackgroundTransparency = 1
        tbLabel.Text = tabName
        tbLabel.TextColor3 = Color3.new(0, 0, 0)
        tbLabel.TextSize = 20
        tbLabel.Font = Enum.Font.SourceSansBold
        tbLabel.TextXAlignment = Enum.TextXAlignment.Left
        tbLabel.Parent = tabBtn

        local logFrame = Instance.new("ScrollingFrame")
        logFrame.Size = UDim2.new(1, 0, 1, 0)
        logFrame.BackgroundTransparency = 1
        logFrame.BorderSizePixel = 0
        logFrame.ScrollBarThickness = 3
        logFrame.ScrollBarImageColor3 = Color3.new(0.4, 0.4, 0.4)
        logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        logFrame.Visible = false
        logFrame.Parent = ShowFrame

        local lfLayout = Instance.new("UIListLayout")
        lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
        lfLayout.Padding = UDim.new(0, 2)
        lfLayout.Parent = logFrame

        local tab = { name = tabName, btn = tabBtn, logFrame = logFrame, logs = {} }

        -- ЛКМ — активация
        tabBtn.MouseButton1Click:Connect(function()
            hideContextMenu()
            setActiveTab(tab)
        end)

        -- ПКМ — контекстное меню
        tabBtn.MouseButton2Click:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            showContextMenu(mouse.X, mouse.Y, "tab")
            cmTarget = tab
        end)

        table.insert(Tabs, tab)
        setActiveTab(tab)
        return tab
    end

    -- // ПКМ по пустому месту TabFrame
    TabFrame.MouseButton2Click = nil
    TabFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            local mouse = LocalPlayer:GetMouse()
            local hit = false
            for _, tab in ipairs(Tabs) do
                if tab.btn and tab.btn.AbsolutePosition and
                    mouse.Y >= tab.btn.AbsolutePosition.Y and
                    mouse.Y <= tab.btn.AbsolutePosition.Y + tab.btn.AbsoluteSize.Y then
                    hit = true break
                end
            end
            if not hit then
                showContextMenu(mouse.X, mouse.Y, "empty")
            end
        end
    end)

    -- // ПКМ по Console
    ConsoleButton.MouseButton2Click:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        showContextMenu(mouse.X, mouse.Y, "console")
        cmTarget = "console"
    end)

    -- // Контекстное меню — действия
    CM_Close.MouseButton1Click:Connect(function()
        if type(cmTarget) == "table" then
            local tab = cmTarget
            tab.logFrame:Destroy()
            tab.btn:Destroy()
            for i, t in ipairs(Tabs) do
                if t == tab then table.remove(Tabs, i) break end
            end
            if ActiveTab == tab then
                ActiveTab = nil
                if #Tabs > 0 then setActiveTab(Tabs[#Tabs]) end
            end
        end
        hideContextMenu()
    end)

    CM_Clear.MouseButton1Click:Connect(function()
        if cmTarget == "console" then
            for _, c in ipairs(ConsoleLogFrame:GetChildren()) do
                if not c:IsA("UIListLayout") then c:Destroy() end
            end
        elseif type(cmTarget) == "table" then
            local tab = cmTarget
            for _, c in ipairs(tab.logFrame:GetChildren()) do
                if not c:IsA("UIListLayout") then c:Destroy() end
            end
            tab.logs = {}
        end
        hideContextMenu()
    end)

    CM_Create.MouseButton1Click:Connect(function()
        createTab()
        hideContextMenu()
    end)

    -- // Закрыть контекстное меню по ЛКМ в любое место
    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if ContextMenu.Visible then
                hideContextMenu()
            end
        end
    end)

    -- // Run логика
    local function parseURL(code)
        return code:match('HttpGet%("([^"]+)"%)') or code:match("HttpGet%('([^']+)'%)")
    end

    local function runScript(code)
        local targetFrame = consoleMode and ConsoleLogFrame or (ActiveTab and ActiveTab.logFrame)
        if not targetFrame then return end

        local url = parseURL(code)
        if url and CheckURL then
            local blocked, msg = CheckURL(url)
            if blocked then addLog(targetFrame, msg, "urlda") return end
        end

        if AntiDC then
            local blocked = AntiDC:CheckCode(code)
            if blocked then addLog(targetFrame, "[DC] AntiDebugConsole protection.", "error") return end
        end

        task.spawn(function()
            if url then
                addLog(targetFrame, "Loading from " .. url .. "...", "system")
            end

            local fn, err = loadstring(code)
            if not fn then
                addLog(targetFrame, "Compile error: " .. tostring(err), "error")
                return
            end

            local env = getfenv(fn)
            env.print = function(...)
                local parts = {}
                for _, v in ipairs({...}) do table.insert(parts, tostring(v)) end
                addLog(targetFrame, table.concat(parts, "\t"), "print")
            end
            env.warn = function(...)
                local parts = {}
                for _, v in ipairs({...}) do table.insert(parts, tostring(v)) end
                addLog(targetFrame, table.concat(parts, "\t"), "warn")
            end

            local ok, runErr = pcall(fn)
            if not ok then addLog(targetFrame, tostring(runErr), "error") end
        end)
    end

    -- // Execute
    ExecuteButton.MouseButton1Click:Connect(function()
        local text = InputCodeBox.Text
        if text == "" then return end
        if not processInput(text) then
            runScript(text)
        end
    end)

    -- // Console кнопка ЛКМ
    ConsoleButton.MouseButton1Click:Connect(function()
        hideContextMenu()
        if consoleMode then
            consoleMode = false
            ConsoleLogFrame.Visible = false
            ConsoleButton.BackgroundColor3 = Color3.new(0.478431, 0.478431, 0.478431)
            if #Tabs > 0 then setActiveTab(Tabs[#Tabs]) end
        else
            setConsoleActive()
        end
    end)

    -- // LogService зеркало
    game:GetService("LogService").MessageOut:Connect(function(msg, msgType)
        if not consoleMode then return end
        local t = "print"
        if msgType == Enum.MessageType.MessageWarning then t = "warn"
        elseif msgType == Enum.MessageType.MessageError then t = "error" end
        addLog(ConsoleLogFrame, msg, t)
    end)

    -- // HideButton
    HideButton.MouseButton1Click:Connect(function()
        Window.Visible = not Window.Visible
    end)

    -- // CloseButton
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        if DevConsole then DevConsole.Enabled = true end
    end)

    -- // Drag
    local dragging, dragStart, startPos
    ButtonContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
        end
    end)
    ButtonContainer.InputEnded:Connect(function(input)
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
    ResizeButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = {
                win = Window.Size,
                sf  = ShowFrame.Size,
                bc  = ButtonContainer.Size,
            }
        end
    end)
    ResizeButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newW = math.max(500, startSize.win.X.Offset + delta.X)
            local newH = math.max(350, startSize.win.Y.Offset + delta.Y)
            Window.Size = UDim2.new(0, newW, 0, newH)
            ShowFrame.Size = UDim2.new(0, math.max(300, startSize.sf.X.Offset + delta.X), 0, math.max(200, startSize.sf.Y.Offset + delta.Y))
            ButtonContainer.Size = UDim2.new(0, math.max(300, startSize.bc.X.Offset + delta.X), 0, startSize.bc.Y.Offset)
        end
    end)

    -- // F9
    UIS.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F9 then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    -- // Старт
    createTab()

    return { createTab = createTab, addLog = addLog }
end