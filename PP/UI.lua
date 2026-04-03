-- Prototype Phone | UI.lua
-- xELO LLC / SyntoriMS

local UI = {}

local SP        = getgenv().PP.StaticPhone
local SSl       = getgenv().PP.SSl
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players   = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Состояние
local state = {
    visible     = false,
    currentApp  = nil,
    appStack    = {}, -- история навигации
    unread      = {}, -- { [contact_ppsid] = count }
}

-- Корневой GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "PrototypePhone"
ScreenGui.ResetOnSpawn  = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent        = game:GetService("CoreGui")

-- Телефон (основной фрейм)
local Phone = Instance.new("Frame")
Phone.Name              = "Phone"
Phone.Size              = SP.Size
Phone.Position          = SP.Anim.StartPosition()
Phone.BackgroundColor3  = SP.Colors.Background
Phone.BorderSizePixel   = 0
Phone.ClipsDescendants  = true
Phone.Visible           = false
Phone.Parent            = ScreenGui

local PhoneCorner = Instance.new("UICorner")
PhoneCorner.CornerRadius = SP.Layout.CornerRadius
PhoneCorner.Parent       = Phone

-- Фон (топо карта)
local Background = Instance.new("ImageLabel")
Background.Name             = "Background"
Background.Size             = UDim2.new(1, 0, 1, 0)
Background.Position         = UDim2.new(0, 0, 0, 0)
Background.BackgroundTransparency = 1
Background.Image            = SP.Icons.Background
Background.ScaleType        = Enum.ScaleType.Crop
Background.ZIndex           = 1
Background.Parent           = Phone

-- Статус бар
local StatusBar = Instance.new("Frame")
StatusBar.Name              = "StatusBar"
StatusBar.Size              = UDim2.new(1, 0, 0, SP.Layout.StatusBarHeight)
StatusBar.Position          = UDim2.new(0, 0, 0, 0)
StatusBar.BackgroundTransparency = 1
StatusBar.ZIndex            = 10
StatusBar.Parent            = Phone

-- Время
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Name              = "Time"
TimeLabel.Size              = UDim2.new(0, 60, 0, 20)
TimeLabel.Position          = UDim2.new(1, -68, 0, 10)
TimeLabel.BackgroundTransparency = 1
TimeLabel.TextColor3        = SP.Colors.Text
TimeLabel.Font              = SP.Font.Semi
TimeLabel.TextSize          = 13
TimeLabel.Text              = "00:00"
TimeLabel.ZIndex            = 11
TimeLabel.Parent            = StatusBar

-- Плавающий остров
local Island = Instance.new("Frame")
Island.Name                 = "Island"
Island.Size                 = UDim2.new(0, SP.Layout.IslandWidth, 0, SP.Layout.IslandHeight)
Island.Position             = UDim2.new(0.5, -(SP.Layout.IslandWidth / 2), 0, 8)
Island.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
Island.BorderSizePixel      = 0
Island.ZIndex               = 20
Island.Parent               = StatusBar
Island.ClipsDescendants     = true

local IslandCorner = Instance.new("UICorner")
IslandCorner.CornerRadius   = UDim.new(1, 0)
IslandCorner.Parent         = Island

-- Уведомление на острове (текст)
local IslandNotif = Instance.new("TextLabel")
IslandNotif.Name            = "IslandNotif"
IslandNotif.Size            = UDim2.new(1, -8, 1, 0)
IslandNotif.Position        = UDim2.new(0, 8, 0, 0)
IslandNotif.BackgroundTransparency = 1
IslandNotif.TextColor3      = SP.Colors.Text
IslandNotif.Font            = SP.Font.Semi
IslandNotif.TextSize        = 11
IslandNotif.TextXAlignment  = Enum.TextXAlignment.Left
IslandNotif.Text            = ""
IslandNotif.ZIndex          = 21
IslandNotif.Visible         = false
IslandNotif.Parent          = Island

-- Счётчик непрочитанных на острове
local IslandBadge = Instance.new("Frame")
IslandBadge.Name            = "IslandBadge"
IslandBadge.Size            = UDim2.new(0, SP.Layout.NotifBadgeSize, 0, SP.Layout.NotifBadgeSize)
IslandBadge.Position        = UDim2.new(1, -(SP.Layout.NotifBadgeSize + 4), 0.5, -(SP.Layout.NotifBadgeSize / 2))
IslandBadge.BackgroundColor3 = SP.Colors.NotifRed
IslandBadge.BorderSizePixel = 0
IslandBadge.ZIndex          = 22
IslandBadge.Visible         = false
IslandBadge.Parent          = Island

local IslandBadgeCorner = Instance.new("UICorner")
IslandBadgeCorner.CornerRadius = UDim.new(1, 0)
IslandBadgeCorner.Parent    = IslandBadge

local IslandBadgeText = Instance.new("TextLabel")
IslandBadgeText.Size        = UDim2.new(1, 0, 1, 0)
IslandBadgeText.BackgroundTransparency = 1
IslandBadgeText.TextColor3  = SP.Colors.Text
IslandBadgeText.Font        = SP.Font.Bold
IslandBadgeText.TextSize    = 10
IslandBadgeText.Text        = "0"
IslandBadgeText.ZIndex      = 23
IslandBadgeText.Parent      = IslandBadge

-- Десктоп (рабочий стол)
local Desktop = Instance.new("Frame")
Desktop.Name                = "Desktop"
Desktop.Size                = UDim2.new(1, 0, 1, -(SP.Layout.StatusBarHeight + SP.Layout.HomeBarHeight))
Desktop.Position            = UDim2.new(0, 0, 0, SP.Layout.StatusBarHeight)
Desktop.BackgroundTransparency = 1
Desktop.ZIndex              = 5
Desktop.Parent              = Phone

-- Ряд иконок приложений
local AppRow = Instance.new("Frame")
AppRow.Name                 = "AppRow"
AppRow.Size                 = UDim2.new(1, -16, 0, SP.Layout.AppIconSize + 8)
AppRow.Position             = UDim2.new(0, 8, 0, 8)
AppRow.BackgroundTransparency = 1
AppRow.ZIndex               = 6
AppRow.Parent               = Desktop

local AppRowLayout = Instance.new("UIListLayout")
AppRowLayout.FillDirection  = Enum.FillDirection.Horizontal
AppRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
AppRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
AppRowLayout.Padding        = UDim.new(0, 8)
AppRowLayout.Parent         = AppRow

-- Контейнер для приложений (полноэкранный внутри телефона)
local AppContainer = Instance.new("Frame")
AppContainer.Name           = "AppContainer"
AppContainer.Size           = UDim2.new(1, 0, 1, -(SP.Layout.StatusBarHeight + SP.Layout.HomeBarHeight))
AppContainer.Position       = UDim2.new(0, 0, 0, SP.Layout.StatusBarHeight)
AppContainer.BackgroundColor3 = SP.Colors.Background
AppContainer.BorderSizePixel = 0
AppContainer.ZIndex         = 15
AppContainer.Visible        = false
AppContainer.Parent         = Phone
AppContainer.ClipsDescendants = true

local AppCorner = Instance.new("UICorner")
AppCorner.CornerRadius = UDim.new(0, 12)
AppCorner.Parent = AppContainer

-- Home bar
local HomeBar = Instance.new("TextButton")
HomeBar.Name                = "HomeBar"
HomeBar.Size                = UDim2.new(0, SP.Layout.HomeBarWidth, 0, 5)
HomeBar.Position            = UDim2.new(0.5, -(SP.Layout.HomeBarWidth / 2), 1, -14)
HomeBar.BackgroundColor3    = SP.Colors.Text
HomeBar.BorderSizePixel     = 0
HomeBar.Text                = ""
HomeBar.ZIndex              = 30
HomeBar.Parent              = Phone

local HomeBarCorner = Instance.new("UICorner")
HomeBarCorner.CornerRadius  = UDim.new(1, 0)
HomeBarCorner.Parent        = HomeBar

-- Утилиты UI
local function setUnread(count)
    local total = 0
    for _, v in pairs(state.unread) do total = total + v end
    if total > 0 then
        IslandBadge.Visible     = true
        IslandBadgeText.Text    = tostring(total)
    else
        IslandBadge.Visible     = false
    end
end

-- Показать уведомление на острове (2с)
function UI:ShowNotification(sender, message)
    -- Расширить остров
    TweenService:Create(Island, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, SP.Layout.IslandHeight),
    }):Play()

    IslandNotif.Text    = sender .. ": " .. message
    IslandNotif.Visible = true

    task.delay(2, function()
        TweenService:Create(Island, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, SP.Layout.IslandWidth, 0, SP.Layout.IslandHeight),
        }):Play()
        task.wait(0.3)
        IslandNotif.Visible = false
        IslandNotif.Text    = ""
    end)
end

-- Открыть приложение
function UI:OpenApp(appId)
    if not getgenv().PP.Apps or not getgenv().PP.Apps[appId] then return end

    AppContainer.Visible = true
    Desktop.Visible      = false

    -- Очистить контейнер
    for _, child in ipairs(AppContainer:GetChildren()) do
        child:Destroy()
    end

    table.insert(state.appStack, appId)
    state.currentApp = appId

    getgenv().PP.Apps[appId]:Render(AppContainer)
end

-- Закрыть приложение / home
function UI:GoBack()
    if #state.appStack > 1 then
        table.remove(state.appStack)
        local prev = state.appStack[#state.appStack]
        self:OpenApp(prev)
    else
        state.appStack  = {}
        state.currentApp = nil
        AppContainer.Visible = false
        Desktop.Visible      = true
    end
end

-- Показать / скрыть телефон
function UI:Toggle()
    if state.visible then
        -- Скрыть
        local tween = TweenService:Create(Phone, SP.Anim.HideTweenInfo, {
            Position = SP.Anim.StartPosition(),
        })
        tween:Play()
        tween.Completed:Connect(function()
            Phone.Visible = false
        end)
        state.visible = false
    else
        -- Показать
        Phone.Position = SP.Anim.StartPosition()
        Phone.Visible  = true
        TweenService:Create(Phone, SP.Anim.TweenInfo, {
            Position = SP.Anim.EndPosition(),
        }):Play()
        state.visible = true
    end
end

-- Создать иконку приложения
local function createAppIcon(app)
    local btn = Instance.new("ImageButton")
    btn.Name                = app.id
    btn.Size                = UDim2.new(0, SP.Layout.AppIconSize, 0, SP.Layout.AppIconSize)
    btn.BackgroundColor3    = SP.Colors.Accent
    btn.BorderSizePixel     = 0
    btn.Image               = SP.Icons[app.icon] or ""
    btn.ZIndex              = 7
    btn.Parent              = AppRow

    local corner = Instance.new("UICorner")
    corner.CornerRadius     = SP.Layout.AppCornerRadius
    corner.Parent           = btn

    -- Бейдж на иконке
    local badge = Instance.new("Frame")
    badge.Name              = "Badge"
    badge.Size              = UDim2.new(0, SP.Layout.NotifBadgeSize, 0, SP.Layout.NotifBadgeSize)
    badge.Position          = UDim2.new(1, -(SP.Layout.NotifBadgeSize / 2), 0, -(SP.Layout.NotifBadgeSize / 2))
    badge.BackgroundColor3  = SP.Colors.NotifRed
    badge.BorderSizePixel   = 0
    badge.ZIndex            = 8
    badge.Visible           = false
    badge.Parent            = btn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(1, 0)
    badgeCorner.Parent      = badge

    local badgeText = Instance.new("TextLabel")
    badgeText.Size          = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.TextColor3    = SP.Colors.Text
    badgeText.Font          = SP.Font.Bold
    badgeText.TextSize      = 10
    badgeText.Text          = "0"
    badgeText.ZIndex        = 9
    badgeText.Parent        = badge

    btn.MouseButton1Click:Connect(function()
        UI:OpenApp(app.id)
    end)

    return btn, badge, badgeText
end

-- Обновить бейдж на иконке
function UI:SetAppBadge(appId, count)
    state.unread[appId] = count
    local btn = AppRow:FindFirstChild(appId)
    if btn then
        local badge = btn:FindFirstChild("Badge")
        local badgeText = badge and badge:FindFirstChild("TextLabel")
        if badge then
            badge.Visible = count > 0
            if badgeText then badgeText.Text = tostring(count) end
        end
    end
    setUnread()
end

-- Инициализация
function UI:Init()
    -- Иконки приложений (появляются по мере загрузки)
    getgenv().PP.Apps = {}

    for _, app in ipairs(SP.Apps) do
        task.spawn(function()
            local ok, module = pcall(function()
                return loadstring(game:HttpGet(getgenv().PP.AppURLs[app.id]))()
            end)
            if ok and module then
                getgenv().PP.Apps[app.id] = module
                createAppIcon(app) -- появляется сразу после загрузки
            else
                warn("[PP] Failed to load app: " .. app.id)
            end
        end)
    end

    -- Часы
    task.spawn(function()
        while true do
            TimeLabel.Text = os.date("%H:%M")
            task.wait(30)
        end
    end)

    -- Home bar
    HomeBar.MouseButton1Click:Connect(function()
        self:GoBack()
    end)

    -- Хоткей Ctrl+F4
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == SP.Hotkey.Key then
            if UserInputService:IsKeyDown(SP.Hotkey.Modifier) then
                self:Toggle()
            end
        end
    end)

    -- Поллинг сообщений
    SSl:PollMessages(function(msg)
        -- Обновить бейдж
        local current = state.unread[msg.sender_ppsid] or 0
        self:SetAppBadge("Messages", current + 1)
        -- Уведомление на острове
        local sender = msg.sender_ppsid -- заменится на username позже
        self:ShowNotification(sender, msg.message)
        -- Если открыт чат с этим юзером — обновить
        if state.currentApp == "Messages" and getgenv().PP.Apps.Messages then
            getgenv().PP.Apps.Messages:OnNewMessage(msg)
        end
    end)
end

return UI