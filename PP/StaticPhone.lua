-- Prototype Phone | Static Phone
-- xELO LLC / SyntoriMS

local StaticPhone = {}

-- Размер телефона
StaticPhone.Size = UDim2.new(0, 365, 0, 650)

-- Позиция (снизу справа, отступ 5px) - считается от размера экрана
StaticPhone.Position = function()
    local vp = workspace.CurrentCamera.ViewportSize
    return UDim2.new(0, vp.X - 365 - 5, 0, vp.Y - 650 - 5)
end

-- Анимация появления (выезд снизу)
StaticPhone.Anim = {
    -- Стартовая позиция (за экраном снизу)
    StartPosition = function()
        local vp = workspace.CurrentCamera.ViewportSize
        return UDim2.new(0, vp.X - 365 - 5, 0, vp.Y + 650)
    end,
    EndPosition = StaticPhone.Position, -- та же что и Position
    TweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    HideTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
}

-- Цвета
StaticPhone.Colors = {
    Background      = Color3.fromRGB(18, 18, 18),
    Surface         = Color3.fromRGB(28, 28, 28),
    SurfaceLight    = Color3.fromRGB(38, 38, 38),
    Text            = Color3.fromRGB(255, 255, 255),
    TextSecondary   = Color3.fromRGB(160, 160, 160),
    TextMuted       = Color3.fromRGB(90, 90, 90),
    Accent          = Color3.fromRGB(100, 90, 180),   -- фиолетовый (иконки)
    AccentGreen     = Color3.fromRGB(48, 209, 88),    -- кнопка Add
    NotifRed        = Color3.fromRGB(255, 59, 48),    -- счётчик уведомлений
    Border          = Color3.fromRGB(45, 45, 45),
}

-- Шрифт
StaticPhone.Font = {
    Regular  = Enum.Font.Gotham,
    Bold     = Enum.Font.GothamBold,
    Semi     = Enum.Font.GothamSemibold,
    Mono     = Enum.Font.Code,
}

-- Размеры элементов
StaticPhone.Layout = {
    CornerRadius     = UDim.new(0, 40),   -- скругление самого телефона
    AppCornerRadius  = UDim.new(0, 16),   -- скругление иконок приложений
    IslandHeight     = 30,                -- высота плавающего острова
    IslandWidth      = 120,               -- ширина (расширяется при уведомлении)
    StatusBarHeight  = 44,                -- статус бар сверху
    HomeBarHeight    = 20,                -- полоска снизу
    HomeBarWidth     = 120,
    AppIconSize      = 52,                -- размер иконки приложения
    NotifBadgeSize   = 18,                -- красный кружок с цифрой
    MessageBubbleMax = 220,               -- макс ширина пузыря сообщения
    ChatInputHeight  = 44,
}

-- Позиции элементов внутри телефона (относительные, UDim2)
StaticPhone.Positions = {
    Island = UDim2.new(0.5, 0, 0, 8),          -- сверху по центру
    Time   = UDim2.new(1, -12, 0, 10),          -- справа сверху
    AppRow = UDim2.new(0, 0, 0, StaticPhone.Layout.StatusBarHeight), -- ряд иконок
    HomeBar = UDim2.new(0.5, 0, 1, -14),        -- снизу по центру
}

-- Иконки (base64 или asset id)
StaticPhone.Icons = {
    Call     = "base64",
    Messages = "base64",
    Store    = "base64",
    Settings = "base64",
    Back     = "base64",    -- стрелка назад
    Add      = "base64",    -- плюсик
    Background = "base64",  -- обои (топо карта)
}

-- Приложения (порядок на рабочем столе)
StaticPhone.Apps = {
    { id = "Messages", icon = "Messages", label = "Messages" },
    { id = "Contacts", icon = "Contacts", label = "Contacts" },
    { id = "Store",    icon = "Store",    label = "Store"    },
    { id = "Settings", icon = "Settings", label = "Settings" },
}

-- Хоткей
StaticPhone.Hotkey = {
    Key       = Enum.KeyCode.F4,
    Modifier  = Enum.KeyCode.LeftControl,
}

return StaticPhone