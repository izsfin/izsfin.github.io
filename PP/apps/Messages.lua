-- Prototype Phone | Messages.lua
-- xELO LLC / SyntoriMS

local Messages = {}
local SP           = getgenv().PP.StaticPhone
local SSl          = getgenv().PP.SSl
local TweenService = game:GetService("TweenService")

-- Состояние
local state = {
    currentChat = nil, -- ppsid собеседника
    frames      = {},  -- { list = Frame, chat = Frame }
}

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

-- Создать пузырь сообщения
local function createBubble(container, msg, isSelf)
    local profile = SSl:GetOrCreateSelf()

    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize       = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.Parent              = container

    local bubble = Instance.new("TextLabel")
    bubble.AutomaticSize    = Enum.AutomaticSize.XY
    bubble.MaxVisibleGraphemes = math.huge
    bubble.TextWrapped      = true
    bubble.RichText         = false
    bubble.BackgroundColor3 = isSelf and SP.Colors.Accent or SP.Colors.SurfaceLight
    bubble.TextColor3       = SP.Colors.Text
    bubble.Font             = SP.Font.Regular
    bubble.TextSize         = 13
    bubble.Text             = msg.message
    bubble.BorderSizePixel  = 0
    bubble.ZIndex           = 2

    -- Ограничение ширины
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(SP.Layout.MessageBubbleMax, math.huge)
    sizeConstraint.Parent  = bubble

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft   = UDim.new(0, 10)
    padding.PaddingRight  = UDim.new(0, 10)
    padding.PaddingTop    = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent        = bubble

    makeCorner(bubble, 14)

    -- Время
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size              = UDim2.new(0, 60, 0, 12)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3        = SP.Colors.TextMuted
    timeLabel.Font              = SP.Font.Regular
    timeLabel.TextSize          = 9
    timeLabel.Text              = msg.timestamp and msg.timestamp:sub(1, 8) or ""
    timeLabel.ZIndex            = 2

    if isSelf then
        bubble.Position         = UDim2.new(1, -8, 0, 4)
        bubble.AnchorPoint      = Vector2.new(1, 0)
        timeLabel.Position      = UDim2.new(1, -8, 0, 0)
        timeLabel.AnchorPoint   = Vector2.new(1, 0)
        timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    else
        bubble.Position         = UDim2.new(0, 8, 0, 4)
        bubble.AnchorPoint      = Vector2.new(0, 0)
        timeLabel.Position      = UDim2.new(0, 8, 0, 0)
        timeLabel.AnchorPoint   = Vector2.new(0, 0)
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    bubble.Parent    = row
    timeLabel.Parent = row

    return row
end

-- Экран чата
local function buildChat(container, contact)
    local frame = Instance.new("Frame")
    frame.Name              = "Chat"
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

    -- Кнопка назад
    local backBtn = Instance.new("TextButton")
    backBtn.Size            = UDim2.new(0, 60, 1, 0)
    backBtn.BackgroundTransparency = 1
    backBtn.TextColor3      = SP.Colors.Accent
    backBtn.Font            = SP.Font.Semi
    backBtn.TextSize        = 13
    backBtn.Text            = "< back"
    backBtn.ZIndex          = 6
    backBtn.Parent          = header

    -- Имя контакта + номер
    local nameLabel = makeLabel({
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 60, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.Text,
        Font = SP.Font.Bold,
        TextSize = 14,
        Text = contact.username,
        ZIndex = 6,
    })
    nameLabel.Parent = header

    local numLabel = makeLabel({
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -68, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.TextMuted,
        Font = SP.Font.Regular,
        TextSize = 10,
        Text = "[ +" .. contact.ppnumber .. " ]",
        ZIndex = 6,
    })
    numLabel.Parent = header

    -- Скролл сообщений
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size             = UDim2.new(1, 0, 1, -(44 + SP.Layout.ChatInputHeight + 8))
    scroll.Position         = UDim2.new(0, 0, 0, 44)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel  = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = SP.Colors.Border
    scroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex           = 2
    scroll.Parent           = frame

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.FillDirection = Enum.FillDirection.Vertical
    scrollLayout.Padding    = UDim.new(0, 4)
    scrollLayout.Parent     = scroll

    -- Пустое состояние
    local emptyLabel = makeLabel({
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.TextMuted,
        Font = SP.Font.Regular,
        TextSize = 12,
        Text = "No messages...",
        ZIndex = 2,
    })
    emptyLabel.Parent = scroll

    -- Загрузить историю
    local profile  = SSl:GetOrCreateSelf()
    local history  = SSl:GetHistory(contact.ppsid)

    if #history > 0 then
        emptyLabel.Visible = false
        for _, msg in ipairs(history) do
            local isSelf = msg.sender == profile.ppsid
            createBubble(scroll, msg, isSelf)
        end
    end

    -- Скролл вниз
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
    end)

    -- Инпут
    local inputBar = Instance.new("Frame")
    inputBar.Size           = UDim2.new(1, -16, 0, SP.Layout.ChatInputHeight)
    inputBar.Position       = UDim2.new(0, 8, 1, -(SP.Layout.ChatInputHeight + 8))
    inputBar.BackgroundColor3 = SP.Colors.Surface
    inputBar.BorderSizePixel = 0
    inputBar.ZIndex         = 5
    inputBar.Parent         = frame
    makeCorner(inputBar, 22)

    local inputBox = Instance.new("TextBox")
    inputBox.Size           = UDim2.new(1, -70, 1, 0)
    inputBox.Position       = UDim2.new(0, 12, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.TextColor3     = SP.Colors.Text
    inputBox.PlaceholderText = "Message..."
    inputBox.PlaceholderColor3 = SP.Colors.TextMuted
    inputBox.Font           = SP.Font.Regular
    inputBox.TextSize       = 13
    inputBox.Text           = ""
    inputBox.ClearTextOnFocus = false
    inputBox.ZIndex         = 6
    inputBox.Parent         = inputBar

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size            = UDim2.new(0, 56, 0, 32)
    sendBtn.Position        = UDim2.new(1, -60, 0.5, -16)
    sendBtn.BackgroundColor3 = SP.Colors.Accent
    sendBtn.TextColor3      = SP.Colors.Text
    sendBtn.Font            = SP.Font.Bold
    sendBtn.TextSize        = 12
    sendBtn.Text            = "SEND"
    sendBtn.BorderSizePixel = 0
    sendBtn.ZIndex          = 6
    sendBtn.Parent          = inputBar
    makeCorner(sendBtn, 16)

    -- Отправка
    local function sendMessage()
        local text = inputBox.Text
        if text == "" or text:len() > 200 then return end
        inputBox.Text = ""

        local msg = {
            sender    = profile.ppsid,
            message   = text,
            timestamp = os.date("%H:%M:%S_%d.%m.%Y"),
        }

        emptyLabel.Visible = false
        createBubble(scroll, msg, true)

        task.defer(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)

        SSl:QueueMessage(contact.ppsid, text)
    end

    sendBtn.MouseButton1Click:Connect(sendMessage)
    inputBox.FocusLost:Connect(function(enter)
        if enter then sendMessage() end
    end)

    -- Назад
    backBtn.MouseButton1Click:Connect(function()
        state.currentChat = nil
        frame:Destroy()
        if state.frames.list then
            state.frames.list.Visible = true
        end
    end)

    -- Получение нового сообщения
    function Messages:OnNewMessage(msg)
        if state.currentChat ~= msg.sender_ppsid then return end
        emptyLabel.Visible = false
        createBubble(scroll, {
            sender    = msg.sender_ppsid,
            message   = msg.message,
            timestamp = msg.timestamp,
        }, false)
        task.defer(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end

    state.frames.chat = frame
    return frame
end

-- Экран списка контактов/чатов
local function buildList(container)
    local frame = Instance.new("Frame")
    frame.Name              = "MessagesList"
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
        Text = "Messages",
        ZIndex = 6,
    })
    title.Parent = header

    -- Список
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

    -- Контакты
    local contacts = SSl:GetContacts()

    for _, contact in ipairs(contacts) do
        local history = SSl:GetHistory(contact.ppsid)
        local lastMsg = history[#history]

        local row = Instance.new("TextButton")
        row.Size            = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = SP.Colors.Surface
        row.BorderSizePixel = 0
        row.Text            = ""
        row.ZIndex          = 3
        row.Parent          = scroll

        -- Имя
        local nameL = makeLabel({
            Size = UDim2.new(1, -80, 0, 20),
            Position = UDim2.new(0, 12, 0, 8),
            BackgroundTransparency = 1,
            TextColor3 = SP.Colors.Text,
            Font = SP.Font.Bold,
            TextSize = 13,
            Text = contact.username,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4,
        })
        nameL.Parent = row

        -- Номер
        local numL = makeLabel({
            Size = UDim2.new(0, 70, 0, 16),
            Position = UDim2.new(1, -78, 0, 10),
            BackgroundTransparency = 1,
            TextColor3 = SP.Colors.TextMuted,
            Font = SP.Font.Regular,
            TextSize = 10,
            Text = "[ +" .. contact.ppnumber .. " ]",
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 4,
        })
        numL.Parent = row

        -- Последнее сообщение
        local lastL = makeLabel({
            Size = UDim2.new(1, -24, 0, 16),
            Position = UDim2.new(0, 12, 0, 30),
            BackgroundTransparency = 1,
            TextColor3 = SP.Colors.TextSecondary,
            Font = SP.Font.Regular,
            TextSize = 11,
            Text = lastMsg and lastMsg.message or "No messages...",
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4,
        })
        lastL.Parent = row

        row.MouseButton1Click:Connect(function()
            state.currentChat = contact.ppsid
            frame.Visible = false
            buildChat(container, contact)
            -- Сбросить бейдж
            getgenv().PP.UI:SetAppBadge("Messages", 0)
        end)
    end

    state.frames.list = frame
    return frame
end

-- Render (вызывается из UI.lua)
function Messages:Render(container)
    state.frames = {}
    state.currentChat = nil
    buildList(container)
end

return Messages