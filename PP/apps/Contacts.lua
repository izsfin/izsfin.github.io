-- Prototype Phone | Contacts.lua
-- xELO LLC / SyntoriMS

local Contacts = {}
local SP           = getgenv().PP.StaticPhone
local SSl          = getgenv().PP.SSl
local TweenService = game:GetService("TweenService")

-- Утилиты
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeLabel(props)
    local l = Instance.new("TextLabel")
    for k, v in pairs(props) do l[k] = v end
    return l
end

-- Состояние
local state = {
    frames = {},
    searching = false,
}

-- Экран поиска (по username)
local function buildSearch(container, onBack)
    local frame = Instance.new("Frame")
    frame.Name              = "ContactSearch"
    frame.Size              = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3  = SP.Colors.Background
    frame.BorderSizePixel   = 0
    frame.Parent            = container

    -- Шапка
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = SP.Colors.Surface
    header.BorderSizePixel  = 0
    header.ZIndex           = 5
    header.Parent           = frame

    local backBtn = Instance.new("TextButton")
    backBtn.Size            = UDim2.new(0, 60, 1, 0)
    backBtn.BackgroundTransparency = 1
    backBtn.TextColor3      = SP.Colors.Accent
    backBtn.Font            = SP.Font.Semi
    backBtn.TextSize        = 13
    backBtn.Text            = "< back"
    backBtn.ZIndex          = 6
    backBtn.Parent          = header

    local title = makeLabel({
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 60, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.Text,
        Font = SP.Font.Bold,
        TextSize = 16,
        Text = "Add Contact",
        ZIndex = 6,
    })
    title.Parent = header

    -- Инпут
    local inputBar = Instance.new("Frame")
    inputBar.Size           = UDim2.new(1, -16, 0, SP.Layout.ChatInputHeight)
    inputBar.Position       = UDim2.new(0, 8, 0, 52)
    inputBar.BackgroundColor3 = SP.Colors.Surface
    inputBar.BorderSizePixel = 0
    inputBar.ZIndex         = 5
    inputBar.Parent         = frame
    makeCorner(inputBar, 22)

    local inputBox = Instance.new("TextBox")
    inputBox.Size           = UDim2.new(1, -24, 1, 0)
    inputBox.Position       = UDim2.new(0, 12, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.TextColor3     = SP.Colors.Text
    inputBox.PlaceholderText = "Enter username..."
    inputBox.PlaceholderColor3 = SP.Colors.TextMuted
    inputBox.Font           = SP.Font.Regular
    inputBox.TextSize       = 13
    inputBox.Text           = ""
    inputBox.ClearTextOnFocus = false
    inputBox.ZIndex         = 6
    inputBox.Parent         = inputBar

    -- Результат поиска
    local resultFrame = Instance.new("Frame")
    resultFrame.Size        = UDim2.new(1, -16, 0, 64)
    resultFrame.Position    = UDim2.new(0, 8, 0, 104)
    resultFrame.BackgroundColor3 = SP.Colors.Surface
    resultFrame.BorderSizePixel = 0
    resultFrame.ZIndex      = 5
    resultFrame.Visible     = false
    resultFrame.Parent      = frame
    makeCorner(resultFrame, 12)

    local resultName = makeLabel({
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.Text,
        Font = SP.Font.Bold,
        TextSize = 14,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })
    resultName.Parent = resultFrame

    local resultNum = makeLabel({
        Size = UDim2.new(1, -24, 0, 16),
        Position = UDim2.new(0, 12, 0, 32),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.TextMuted,
        Font = SP.Font.Regular,
        TextSize = 11,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })
    resultNum.Parent = resultFrame

    -- Кнопка Add
    local addBtn = Instance.new("TextButton")
    addBtn.Size             = UDim2.new(0, 48, 0, 28)
    addBtn.Position         = UDim2.new(1, -56, 0.5, -14)
    addBtn.BackgroundColor3 = SP.Colors.AccentGreen
    addBtn.TextColor3       = SP.Colors.Text
    addBtn.Font             = SP.Font.Bold
    addBtn.TextSize         = 12
    addBtn.Text             = "Add"
    addBtn.BorderSizePixel  = 0
    addBtn.ZIndex           = 6
    addBtn.Parent           = resultFrame
    makeCorner(addBtn, 8)

    -- Статус
    local statusLabel = makeLabel({
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 176),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.TextMuted,
        Font = SP.Font.Regular,
        TextSize = 11,
        Text = "",
        ZIndex = 5,
    })
    statusLabel.Parent = frame

    -- Найденный юзер
    local foundUser = nil

    local function doSearch()
        local username = inputBox.Text
        if username == "" then return end

        statusLabel.Text    = "Searching..."
        resultFrame.Visible = false
        foundUser           = nil

        task.spawn(function()
            local user = SSl:FindUser(username)
            if user then
                foundUser           = user
                resultName.Text     = user.username
                resultNum.Text      = "[ +" .. user.ppnumber .. " ]"
                resultFrame.Visible = true
                statusLabel.Text    = ""
            else
                statusLabel.Text    = "User not found."
            end
        end)
    end

    inputBox.FocusLost:Connect(function(enter)
        if enter then doSearch() end
    end)

    addBtn.MouseButton1Click:Connect(function()
        if not foundUser then return end

        -- Проверить дубликат
        local existing = SSl:GetContacts()
        for _, c in ipairs(existing) do
            if c.ppsid == foundUser.ppsid then
                statusLabel.Text = "Already in contacts."
                return
            end
        end

        SSl:AddContact(foundUser)
        statusLabel.Text    = "Added: " .. foundUser.username
        resultFrame.Visible = false
        foundUser           = nil
        inputBox.Text       = ""

        -- Обновить список
        task.delay(0.5, function()
            frame:Destroy()
            if onBack then onBack() end
        end)
    end)

    backBtn.MouseButton1Click:Connect(function()
        frame:Destroy()
        if onBack then onBack() end
    end)

    return frame
end

-- Строка контакта
local function createContactRow(scroll, contact, onOpen)
    local row = Instance.new("TextButton")
    row.Size            = UDim2.new(1, 0, 0, 60)
    row.BackgroundColor3 = SP.Colors.Surface
    row.BorderSizePixel = 0
    row.Text            = ""
    row.ZIndex          = 3
    row.Parent          = scroll

    local nameL = makeLabel({
        Size = UDim2.new(1, -90, 0, 22),
        Position = UDim2.new(0, 12, 0, 10),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.Text,
        Font = SP.Font.Bold,
        TextSize = 14,
        Text = contact.username,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })
    nameL.Parent = row

    local numL = makeLabel({
        Size = UDim2.new(0, 80, 0, 16),
        Position = UDim2.new(1, -88, 0, 12),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.TextMuted,
        Font = SP.Font.Regular,
        TextSize = 10,
        Text = "[ +" .. contact.ppnumber .. " ]",
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 4,
    })
    numL.Parent = row

    -- Разделитель
    local divider = Instance.new("Frame")
    divider.Size            = UDim2.new(1, -12, 0, 1)
    divider.Position        = UDim2.new(0, 12, 1, -1)
    divider.BackgroundColor3 = SP.Colors.Border
    divider.BorderSizePixel = 0
    divider.ZIndex          = 3
    divider.Parent          = row

    row.MouseButton1Click:Connect(function()
        if onOpen then onOpen(contact) end
    end)

    return row
end

-- Главный экран контактов
local function buildList(container)
    local frame = Instance.new("Frame")
    frame.Name              = "ContactsList"
    frame.Size              = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3  = SP.Colors.Background
    frame.BorderSizePixel   = 0
    frame.Parent            = container

    -- Шапка
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = SP.Colors.Surface
    header.BorderSizePixel  = 0
    header.ZIndex           = 5
    header.Parent           = frame

    local title = makeLabel({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.Text,
        Font = SP.Font.Bold,
        TextSize = 16,
        Text = "Contacts",
        ZIndex = 6,
    })
    title.Parent = header

    -- Скролл
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size             = UDim2.new(1, 0, 1, -44)
    scroll.Position         = UDim2.new(0, 0, 0, 44)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel  = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = SP.Colors.Border
    scroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex           = 2
    scroll.Parent           = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding      = UDim.new(0, 1)
    listLayout.Parent       = scroll

    -- Загрузить контакты
    local contacts = SSl:GetContacts()

    if #contacts == 0 then
        local emptyL = makeLabel({
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            TextColor3 = SP.Colors.TextMuted,
            Font = SP.Font.Regular,
            TextSize = 12,
            Text = "No contacts yet.",
            ZIndex = 3,
        })
        emptyL.Parent = scroll
    else
        for _, contact in ipairs(contacts) do
            createContactRow(scroll, contact, function(c)
                -- Открыть чат через Messages
                if getgenv().PP.Apps and getgenv().PP.Apps.Messages then
                    getgenv().PP.UI:OpenApp("Messages")
                    -- небольшая задержка чтоб Messages успел отрендериться
                    task.delay(0.1, function()
                        getgenv().PP.Apps.Messages:OpenChat(c)
                    end)
                end
            end)
        end
    end

    -- Кнопка Add (плюсик снизу слева)
    local addBtn = Instance.new("TextButton")
    addBtn.Size             = UDim2.new(0, 44, 0, 44)
    addBtn.Position         = UDim2.new(0, 12, 1, -(44 + 12))
    addBtn.BackgroundColor3 = SP.Colors.AccentGreen
    addBtn.TextColor3       = SP.Colors.Text
    addBtn.Font             = SP.Font.Bold
    addBtn.TextSize         = 24
    addBtn.Text             = "+"
    addBtn.BorderSizePixel  = 0
    addBtn.ZIndex           = 10
    addBtn.Parent           = frame
    makeCorner(addBtn, 22)

    addBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        buildSearch(container, function()
            -- После добавления — обновить список
            frame:Destroy()
            buildList(container)
        end)
    end)

    state.frames.list = frame
    return frame
end

function Contacts:Render(container)
    state.frames = {}
    buildList(container)
end

return Contacts