-- NightX | Nixu Hub
-- ethereos.vercel.app

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ═══════════════════════════════════════
--           КОНФИГ
-- ═══════════════════════════════════════
local CONFIG = {
    Title       = "Nixu Hub",
    Version     = "v1.0.0",
    Author      = "nilletMS",
    Website     = "ethereos.vercel.app",
    Discord     = "discord.gg/TRPZg4Xfkq",
    UpdateDate  = "08.03.2026",
    AccentColor = Color3.fromRGB(120, 100, 220),
    BgColor     = Color3.fromRGB(18, 18, 22),
    PanelColor  = Color3.fromRGB(28, 28, 34),
    CardColor   = Color3.fromRGB(38, 38, 46),
}

-- ═══════════════════════════════════════
--           СКРИПТЫ (замени на свои)
-- ═══════════════════════════════════════
local SCRIPTS = {
    { name = "Spectral [CMD]",  preview = "",  execute = function() print("Spectral CMD loaded") end },
    { name = "Nixu",            preview = "",  execute = function() print("Nixu loaded") end },
    { name = "Esp",             preview = "",  execute = function() print("Esp loaded") end },
    { name = "Auto Farm",       preview = "",  execute = function() print("AutoFarm loaded") end },
    { name = "Speed",           preview = "",  execute = function() print("Speed loaded") end },
    { name = "Fly",             preview = "",  execute = function() print("Fly loaded") end },
    { name = "Inf Jump",        preview = "",  execute = function() print("InfJump loaded") end },
    { name = "No Clip",         preview = "",  execute = function() print("NoClip loaded") end },
    { name = "Aimbot",          preview = "",  execute = function() print("Aimbot loaded") end },
    { name = "WallHack",        preview = "",  execute = function() print("WallHack loaded") end },
    { name = "Teleport",        preview = "",  execute = function() print("Teleport loaded") end },
    { name = "God Mode",        preview = "",  execute = function() print("GodMode loaded") end },
    { name = "Kill Aura",       preview = "",  execute = function() print("KillAura loaded") end },
    { name = "Spin Bot",        preview = "",  execute = function() print("SpinBot loaded") end },
    { name = "Anti AFK",        preview = "",  execute = function() print("AntiAFK loaded") end },
}

-- ═══════════════════════════════════════
--           УТИЛИТЫ
-- ═══════════════════════════════════════
local function tween(obj, props, t, style, dir)
    local ti = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, ti, props):Play()
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makePadding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60,60,70)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.7
    s.Parent = parent
    return s
end

-- ═══════════════════════════════════════
--           ГЛАВНЫЙ GUI
-- ═══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NixuHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = (gethui and gethui()) or player.PlayerGui

-- Главное окно
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 680, 0, 520)
Main.Position = UDim2.new(0.5, -340, 0.5, -260)
Main.BackgroundColor3 = CONFIG.BgColor
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
makeCorner(Main, 14)
makeStroke(Main, Color3.fromRGB(60,55,80), 1, 0.5)

-- Тень
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.fromRGB(0,0,0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49,49,450,450)
Shadow.ZIndex = 0
Shadow.Parent = Main

-- ═══════════════════════════════════════
--           БОКОВАЯ ПАНЕЛЬ
-- ═══════════════════════════════════════
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 44, 1, 0)
Sidebar.Position = UDim2.new(0, 0, 0, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 5
Sidebar.Parent = Main

-- Разделитель
local SideDiv = Instance.new("Frame")
SideDiv.Size = UDim2.new(0, 1, 1, 0)
SideDiv.Position = UDim2.new(1, 0, 0, 0)
SideDiv.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
SideDiv.BorderSizePixel = 0
SideDiv.ZIndex = 5
SideDiv.Parent = Sidebar

local SideList = Instance.new("UIListLayout")
SideList.FillDirection = Enum.FillDirection.Vertical
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.VerticalAlignment = Enum.VerticalAlignment.Top
SideList.Padding = UDim.new(0, 6)
SideList.Parent = Sidebar
makePadding(Sidebar, 10, 10, 0, 0)

-- Функция создания кнопки сайдбара
local function makeSideBtn(icon, isImage)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(30, 28, 38)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 6
    btn.Parent = Sidebar
    makeCorner(btn, 7)
    makeStroke(btn, Color3.fromRGB(60,55,80), 1, 0.6)

    if isImage then
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(0, 16, 0, 16)
        img.Position = UDim2.new(0.5, -8, 0.5, -8)
        img.BackgroundTransparency = 1
        img.Image = icon
        img.ImageColor3 = Color3.fromRGB(180, 170, 210)
        img.ZIndex = 7
        img.Parent = btn
    else
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon
        lbl.TextColor3 = Color3.fromRGB(180, 170, 210)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.ZIndex = 7
        lbl.Parent = btn
    end

    return btn
end

-- H — Home (иконка домика)
local BtnHome = makeSideBtn("rbxassetid://11036798237", true)
-- S — Scripts (иконка скриптов)  
local BtnScripts = makeSideBtn("rbxassetid://11034538017", true)

-- Разделитель между верхними и нижними кнопками
local Spacer = Instance.new("Frame")
Spacer.Size = UDim2.new(0, 30, 0, 1)
Spacer.BackgroundColor3 = Color3.fromRGB(50,45,65)
Spacer.BorderSizePixel = 0
Spacer.ZIndex = 6
Spacer.Parent = Sidebar

-- S — Settings (шестерёнка) вверху боковой панели отдельно
local BtnSettings = makeSideBtn("rbxassetid://11293981586", true)

-- ═══════════════════════════════════════
--           КОНТЕНТ ОБЛАСТЬ
-- ═══════════════════════════════════════
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -44, 1, -40)
Content.Position = UDim2.new(0, 44, 0, 0)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Parent = Main

-- ═══════════════════════════════════════
--           НИЖНЯЯ ПОЛОСА (PAGE TITLE)
-- ═══════════════════════════════════════
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 36)
Footer.Position = UDim2.new(0, 0, 1, -36)
Footer.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
Footer.BorderSizePixel = 0
Footer.ZIndex = 5
Footer.Parent = Main

local FooterTitle = Instance.new("TextLabel")
FooterTitle.Size = UDim2.new(1, 0, 1, 0)
FooterTitle.BackgroundTransparency = 1
FooterTitle.Text = "HOME"
FooterTitle.TextColor3 = Color3.fromRGB(220, 215, 235)
FooterTitle.TextSize = 13
FooterTitle.Font = Enum.Font.GothamBold
FooterTitle.ZIndex = 6
FooterTitle.Parent = Footer

local FooterDiv = Instance.new("Frame")
FooterDiv.Size = UDim2.new(1, 0, 0, 1)
FooterDiv.Position = UDim2.new(0, 0, 0, 0)
FooterDiv.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
FooterDiv.BorderSizePixel = 0
FooterDiv.ZIndex = 5
FooterDiv.Parent = Footer

-- ═══════════════════════════════════════
--           СТРАНИЦА: HOME
-- ═══════════════════════════════════════
local PageHome = Instance.new("Frame")
PageHome.Name = "PageHome"
PageHome.Size = UDim2.new(1, 0, 1, 0)
PageHome.BackgroundTransparency = 1
PageHome.Parent = Content

makePadding(PageHome, 10, 10, 10, 10)

local HomeGrid = Instance.new("Frame")
HomeGrid.Size = UDim2.new(1, 0, 1, 0)
HomeGrid.BackgroundTransparency = 1
HomeGrid.Parent = PageHome

-- Большая верхняя карточка (превью / баннер)
local BannerCard = Instance.new("Frame")
BannerCard.Size = UDim2.new(0, 350, 0, 155)
BannerCard.Position = UDim2.new(0, 0, 0, 0)
BannerCard.BackgroundColor3 = CONFIG.CardColor
BannerCard.BorderSizePixel = 0
BannerCard.Parent = HomeGrid
makeCorner(BannerCard, 10)
makeStroke(BannerCard, Color3.fromRGB(60,55,80), 1, 0.6)

local BannerDate = Instance.new("TextLabel")
BannerDate.Size = UDim2.new(1, 0, 0, 30)
BannerDate.Position = UDim2.new(0, 0, 1, -36)
BannerDate.BackgroundTransparency = 1
BannerDate.Text = "Updated  |  " .. CONFIG.UpdateDate
BannerDate.TextColor3 = Color3.fromRGB(200, 195, 220)
BannerDate.TextSize = 13
BannerDate.Font = Enum.Font.Gotham
BannerDate.ZIndex = 2
BannerDate.Parent = BannerCard

-- Changelogs карточка
local ChangeCard = Instance.new("Frame")
ChangeCard.Size = UDim2.new(0, 168, 0, 155)
ChangeCard.Position = UDim2.new(0, 358, 0, 0)
ChangeCard.BackgroundColor3 = CONFIG.CardColor
ChangeCard.BorderSizePixel = 0
ChangeCard.Parent = HomeGrid
makeCorner(ChangeCard, 10)
makeStroke(ChangeCard, Color3.fromRGB(60,55,80), 1, 0.6)

local ChangeTitle = Instance.new("TextLabel")
ChangeTitle.Size = UDim2.new(1, -10, 0, 50)
ChangeTitle.Position = UDim2.new(0, 10, 0, 10)
ChangeTitle.BackgroundTransparency = 1
ChangeTitle.Text = "Changelogs\nin Discord !"
ChangeTitle.TextColor3 = Color3.fromRGB(220, 215, 235)
ChangeTitle.TextSize = 13
ChangeTitle.Font = Enum.Font.GothamBold
ChangeTitle.TextXAlignment = Enum.TextXAlignment.Left
ChangeTitle.ZIndex = 2
ChangeTitle.Parent = ChangeCard

local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(1, -16, 0, 28)
DiscordBtn.Position = UDim2.new(0, 8, 1, -36)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(50, 46, 64)
DiscordBtn.BorderSizePixel = 0
DiscordBtn.Text = "Discord"
DiscordBtn.TextColor3 = Color3.fromRGB(200, 195, 220)
DiscordBtn.TextSize = 12
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.ZIndex = 3
DiscordBtn.Parent = ChangeCard
makeCorner(DiscordBtn, 7)

-- DLC карточка
local DLCCard = Instance.new("Frame")
DLCCard.Size = UDim2.new(0, 100, 0, 155)
DLCCard.Position = UDim2.new(0, 534, 0, 0)
DLCCard.BackgroundColor3 = CONFIG.CardColor
DLCCard.BorderSizePixel = 0
DLCCard.Parent = HomeGrid
makeCorner(DLCCard, 10)
makeStroke(DLCCard, Color3.fromRGB(60,55,80), 1, 0.6)

local DLCTitle = Instance.new("TextLabel")
DLCTitle.Size = UDim2.new(1, -10, 1, 0)
DLCTitle.Position = UDim2.new(0, 10, 0, 10)
DLCTitle.BackgroundTransparency = 1
DLCTitle.Text = "DLC\n" .. CONFIG.Version
DLCTitle.TextColor3 = Color3.fromRGB(220, 215, 235)
DLCTitle.TextSize = 13
DLCTitle.Font = Enum.Font.GothamBold
DLCTitle.TextXAlignment = Enum.TextXAlignment.Left
DLCTitle.TextYAlignment = Enum.TextYAlignment.Top
DLCTitle.ZIndex = 2
DLCTitle.Parent = DLCCard

-- Нижняя строка карточек
-- Карточка "Need key?"
local KeyCard = Instance.new("Frame")
KeyCard.Size = UDim2.new(0, 113, 0, 150)
KeyCard.Position = UDim2.new(0, 0, 0, 165)
KeyCard.BackgroundColor3 = CONFIG.CardColor
KeyCard.BorderSizePixel = 0
KeyCard.Parent = HomeGrid
makeCorner(KeyCard, 10)
makeStroke(KeyCard, Color3.fromRGB(60,55,80), 1, 0.6)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, -10, 0, 22)
KeyTitle.Position = UDim2.new(0, 8, 0, 8)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "Need key?"
KeyTitle.TextColor3 = Color3.fromRGB(220, 215, 235)
KeyTitle.TextSize = 12
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextXAlignment = Enum.TextXAlignment.Left
KeyTitle.ZIndex = 2
KeyTitle.Parent = KeyCard

local KeySub = Instance.new("TextLabel")
KeySub.Size = UDim2.new(1, -10, 0, 40)
KeySub.Position = UDim2.new(0, 8, 0, 28)
KeySub.BackgroundTransparency = 1
KeySub.Text = "Get key in our\nwebsite"
KeySub.TextColor3 = Color3.fromRGB(130, 125, 155)
KeySub.TextSize = 11
KeySub.Font = Enum.Font.Gotham
KeySub.TextXAlignment = Enum.TextXAlignment.Left
KeySub.ZIndex = 2
KeySub.Parent = KeyCard

local KeyBtn = Instance.new("TextButton")
KeyBtn.Size = UDim2.new(1, -16, 0, 26)
KeyBtn.Position = UDim2.new(0, 8, 1, -34)
KeyBtn.BackgroundColor3 = Color3.fromRGB(50, 46, 64)
KeyBtn.BorderSizePixel = 0
KeyBtn.Text = "Link"
KeyBtn.TextColor3 = Color3.fromRGB(200, 195, 220)
KeyBtn.TextSize = 12
KeyBtn.Font = Enum.Font.GothamBold
KeyBtn.ZIndex = 3
KeyBtn.Parent = KeyCard
makeCorner(KeyBtn, 7)

-- Карточка "Created by"
local CreatorCard = Instance.new("Frame")
CreatorCard.Size = UDim2.new(0, 113, 0, 150)
CreatorCard.Position = UDim2.new(0, 121, 0, 165)
CreatorCard.BackgroundColor3 = CONFIG.CardColor
CreatorCard.BorderSizePixel = 0
CreatorCard.Parent = HomeGrid
makeCorner(CreatorCard, 10)
makeStroke(CreatorCard, Color3.fromRGB(60,55,80), 1, 0.6)

local CreatorLabel = Instance.new("TextLabel")
CreatorLabel.Size = UDim2.new(1, -10, 1, -20)
CreatorLabel.Position = UDim2.new(0, 8, 0, 10)
CreatorLabel.BackgroundTransparency = 1
CreatorLabel.Text = "Created by\n" .. CONFIG.Author
CreatorLabel.TextColor3 = Color3.fromRGB(200, 195, 220)
CreatorLabel.TextSize = 12
CreatorLabel.Font = Enum.Font.GothamBold
CreatorLabel.TextXAlignment = Enum.TextXAlignment.Left
CreatorLabel.TextYAlignment = Enum.TextYAlignment.Top
CreatorLabel.ZIndex = 2
CreatorLabel.Parent = CreatorCard

-- Карточки "soon" нижнего ряда
local function makeSoonCard(x, y, w, h)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, w, 0, h)
    card.Position = UDim2.new(0, x, 0, y)
    card.BackgroundColor3 = CONFIG.CardColor
    card.BorderSizePixel = 0
    card.Parent = HomeGrid
    makeCorner(card, 10)
    makeStroke(card, Color3.fromRGB(60,55,80), 1, 0.7)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "soon"
    lbl.TextColor3 = Color3.fromRGB(80,75,100)
    lbl.TextSize = 16
    lbl.Font = Enum.Font.GothamBoldItalic
    lbl.ZIndex = 2
    lbl.Parent = card
    return card
end

makeSoonCard(242, 165, 392, 150)   -- большая карточка soon
makeSoonCard(0,   323, 200, 135)   -- нижние
makeSoonCard(208, 323, 168, 135)
makeSoonCard(384, 323, 100, 135)
makeSoonCard(492, 323, 142, 135)

-- ═══════════════════════════════════════
--           СТРАНИЦА: SCRIPTS
-- ═══════════════════════════════════════
local PageScripts = Instance.new("Frame")
PageScripts.Name = "PageScripts"
PageScripts.Size = UDim2.new(1, 0, 1, 0)
PageScripts.BackgroundTransparency = 1
PageScripts.Visible = false
PageScripts.Parent = Content

local ScriptScroll = Instance.new("ScrollingFrame")
ScriptScroll.Size = UDim2.new(1, 0, 1, 0)
ScriptScroll.BackgroundTransparency = 1
ScriptScroll.BorderSizePixel = 0
ScriptScroll.ScrollBarThickness = 0
ScriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ScriptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScriptScroll.Parent = PageScripts
makePadding(ScriptScroll, 10, 10, 10, 10)

local ScriptGrid = Instance.new("UIGridLayout")
ScriptGrid.CellSize = UDim2.new(0, 118, 0, 148)
ScriptGrid.CellPadding = UDim2.new(0, 8, 0, 8)
ScriptGrid.SortOrder = Enum.SortOrder.LayoutOrder
ScriptGrid.Parent = ScriptScroll

-- Генерация карточек скриптов
for i, script in ipairs(SCRIPTS) do
    local card = Instance.new("Frame")
    card.Name = "Card_" .. i
    card.BackgroundColor3 = CONFIG.CardColor
    card.BorderSizePixel = 0
    card.LayoutOrder = i
    card.Parent = ScriptScroll
    makeCorner(card, 10)
    makeStroke(card, Color3.fromRGB(60,55,80), 1, 0.7)

    -- Превью
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(1, -10, 0, 85)
    preview.Position = UDim2.new(0, 5, 0, 5)
    preview.BackgroundColor3 = Color3.fromRGB(28, 26, 36)
    preview.BorderSizePixel = 0
    preview.ZIndex = 2
    preview.Parent = card
    makeCorner(preview, 7)

    if script.preview ~= "" then
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1,0,1,0)
        img.BackgroundTransparency = 1
        img.Image = script.preview
        img.ScaleType = Enum.ScaleType.Crop
        img.ZIndex = 3
        img.Parent = preview
        makeCorner(img, 7)
    end

    -- Имя скрипта
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 22)
    nameLabel.Position = UDim2.new(0, 5, 0, 95)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = script.name
    nameLabel.TextColor3 = Color3.fromRGB(220, 215, 235)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 2
    nameLabel.Parent = card

    -- Кнопка Execute
    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(1, -10, 0, 24)
    execBtn.Position = UDim2.new(0, 5, 1, -29)
    execBtn.BackgroundColor3 = Color3.fromRGB(50, 46, 64)
    execBtn.BorderSizePixel = 0
    execBtn.Text = "Execute"
    execBtn.TextColor3 = Color3.fromRGB(200, 195, 220)
    execBtn.TextSize = 11
    execBtn.Font = Enum.Font.GothamBold
    execBtn.ZIndex = 3
    execBtn.Parent = card
    makeCorner(execBtn, 6)

    local capturedScript = script
    execBtn.MouseButton1Click:Connect(function()
        tween(execBtn, { BackgroundColor3 = CONFIG.AccentColor }, 0.15)
        task.wait(0.15)
        tween(execBtn, { BackgroundColor3 = Color3.fromRGB(50, 46, 64) }, 0.15)
        task.spawn(capturedScript.execute)
    end)

    execBtn.MouseEnter:Connect(function()
        tween(execBtn, { BackgroundColor3 = Color3.fromRGB(65, 60, 85) }, 0.15)
    end)
    execBtn.MouseLeave:Connect(function()
        tween(execBtn, { BackgroundColor3 = Color3.fromRGB(50, 46, 64) }, 0.15)
    end)
end

-- ═══════════════════════════════════════
--           НАСТРОЙКИ (оверлей)
-- ═══════════════════════════════════════
local SettingsOverlay = Instance.new("Frame")
SettingsOverlay.Name = "SettingsOverlay"
SettingsOverlay.Size = UDim2.new(1, -44, 1, -36)
SettingsOverlay.Position = UDim2.new(0, 44, 0, 0)
SettingsOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
SettingsOverlay.BackgroundTransparency = 0.1
SettingsOverlay.BorderSizePixel = 0
SettingsOverlay.Visible = false
SettingsOverlay.ZIndex = 20
SettingsOverlay.Parent = Main
makeStroke(SettingsOverlay, Color3.fromRGB(60,55,80), 1, 0.5)

makePadding(SettingsOverlay, 20, 20, 20, 20)

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, 0, 0, 24)
SettingsTitle.Position = UDim2.new(0, 0, 0, 0)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "SETTINGS"
SettingsTitle.TextColor3 = Color3.fromRGB(220, 215, 235)
SettingsTitle.TextSize = 13
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.ZIndex = 21
SettingsTitle.Parent = SettingsOverlay

local SettingsDiv = Instance.new("Frame")
SettingsDiv.Size = UDim2.new(1, 0, 0, 1)
SettingsDiv.Position = UDim2.new(0, 0, 0, 32)
SettingsDiv.BackgroundColor3 = Color3.fromRGB(55, 50, 70)
SettingsDiv.BorderSizePixel = 0
SettingsDiv.ZIndex = 21
SettingsDiv.Parent = SettingsOverlay

-- CustomBG Label
local BgLabel = Instance.new("TextLabel")
BgLabel.Size = UDim2.new(1, 0, 0, 18)
BgLabel.Position = UDim2.new(0, 0, 0, 46)
BgLabel.BackgroundTransparency = 1
BgLabel.Text = "CUSTOM BACKGROUND"
BgLabel.TextColor3 = Color3.fromRGB(130, 120, 160)
BgLabel.TextSize = 10
BgLabel.Font = Enum.Font.GothamBold
BgLabel.TextXAlignment = Enum.TextXAlignment.Left
BgLabel.ZIndex = 21
BgLabel.Parent = SettingsOverlay

-- AssetID TextBox
local BgInput = Instance.new("TextBox")
BgInput.Size = UDim2.new(1, 0, 0, 34)
BgInput.Position = UDim2.new(0, 0, 0, 68)
BgInput.BackgroundColor3 = Color3.fromRGB(25, 23, 32)
BgInput.BorderSizePixel = 0
BgInput.Text = ""
BgInput.PlaceholderText = "Asset ID (e.g. 12345678)"
BgInput.PlaceholderColor3 = Color3.fromRGB(80, 75, 100)
BgInput.TextColor3 = Color3.fromRGB(210, 205, 230)
BgInput.TextSize = 12
BgInput.Font = Enum.Font.Gotham
BgInput.ZIndex = 21
BgInput.ClearTextOnFocus = false
BgInput.Parent = SettingsOverlay
makeCorner(BgInput, 8)
makeStroke(BgInput, Color3.fromRGB(60,55,80), 1, 0.5)
makePadding(BgInput, 0, 0, 12, 8)

-- Apply BG Button
local ApplyBgBtn = Instance.new("TextButton")
ApplyBgBtn.Size = UDim2.new(1, 0, 0, 30)
ApplyBgBtn.Position = UDim2.new(0, 0, 0, 108)
ApplyBgBtn.BackgroundColor3 = Color3.fromRGB(50, 46, 64)
ApplyBgBtn.BorderSizePixel = 0
ApplyBgBtn.Text = "Apply"
ApplyBgBtn.TextColor3 = Color3.fromRGB(200, 195, 220)
ApplyBgBtn.TextSize = 12
ApplyBgBtn.Font = Enum.Font.GothamBold
ApplyBgBtn.ZIndex = 21
ApplyBgBtn.Parent = SettingsOverlay
makeCorner(ApplyBgBtn, 8)

-- Transparency Label
local TransLabel = Instance.new("TextLabel")
TransLabel.Size = UDim2.new(1, 0, 0, 18)
TransLabel.Position = UDim2.new(0, 0, 0, 156)
TransLabel.BackgroundTransparency = 1
TransLabel.Text = "BACKGROUND TRANSPARENCY"
TransLabel.TextColor3 = Color3.fromRGB(130, 120, 160)
TransLabel.TextSize = 10
TransLabel.Font = Enum.Font.GothamBold
TransLabel.TextXAlignment = Enum.TextXAlignment.Left
TransLabel.ZIndex = 21
TransLabel.Parent = SettingsOverlay

-- Значение слайдера
local TransValue = Instance.new("TextLabel")
TransValue.Size = UDim2.new(0, 40, 0, 18)
TransValue.Position = UDim2.new(1, -40, 0, 156)
TransValue.BackgroundTransparency = 1
TransValue.Text = "0.00"
TransValue.TextColor3 = Color3.fromRGB(160, 150, 200)
TransValue.TextSize = 10
TransValue.Font = Enum.Font.GothamBold
TransValue.TextXAlignment = Enum.TextXAlignment.Right
TransValue.ZIndex = 21
TransValue.Parent = SettingsOverlay

-- Слайдер трека
local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, 0, 0, 6)
SliderTrack.Position = UDim2.new(0, 0, 0, 182)
SliderTrack.BackgroundColor3 = Color3.fromRGB(35, 32, 46)
SliderTrack.BorderSizePixel = 0
SliderTrack.ZIndex = 21
SliderTrack.Parent = SettingsOverlay
makeCorner(SliderTrack, 3)
makeStroke(SliderTrack, Color3.fromRGB(55,50,70), 1, 0.5)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0, 0, 1, 0)
SliderFill.BackgroundColor3 = CONFIG.AccentColor
SliderFill.BorderSizePixel = 0
SliderFill.ZIndex = 22
SliderFill.Parent = SliderTrack
makeCorner(SliderFill, 3)

local SliderThumb = Instance.new("Frame")
SliderThumb.Size = UDim2.new(0, 14, 0, 14)
SliderThumb.Position = UDim2.new(0, -7, 0.5, -7)
SliderThumb.BackgroundColor3 = Color3.fromRGB(220, 215, 235)
SliderThumb.BorderSizePixel = 0
SliderThumb.ZIndex = 23
SliderThumb.Parent = SliderTrack
makeCorner(SliderThumb, 7)
makeStroke(SliderThumb, CONFIG.AccentColor, 1, 0.3)

-- Close Settings Button
local CloseSettingsBtn = Instance.new("TextButton")
CloseSettingsBtn.Size = UDim2.new(1, 0, 0, 30)
CloseSettingsBtn.Position = UDim2.new(0, 0, 1, -50)
CloseSettingsBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 35)
CloseSettingsBtn.BorderSizePixel = 0
CloseSettingsBtn.Text = "Close Settings"
CloseSettingsBtn.TextColor3 = Color3.fromRGB(240, 100, 100)
CloseSettingsBtn.TextSize = 12
CloseSettingsBtn.Font = Enum.Font.GothamBold
CloseSettingsBtn.ZIndex = 21
CloseSettingsBtn.Parent = SettingsOverlay
makeCorner(CloseSettingsBtn, 8)
makeStroke(CloseSettingsBtn, Color3.fromRGB(180,60,60), 1, 0.6)

-- ═══════════════════════════════════════
--           ЛОГИКА СЛАЙДЕРА
-- ═══════════════════════════════════════
local sliderDragging = false
local currentTransparency = 0

local function updateSlider(val)
    val = math.clamp(val, 0, 0.9)
    currentTransparency = val
    local pct = val / 0.9
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
    TransValue.Text = string.format("%.2f", val)
    Main.BackgroundTransparency = val
end

SliderThumb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local trackPos = SliderTrack.AbsolutePosition.X
        local trackWidth = SliderTrack.AbsoluteSize.X
        local mouseX = input.Position.X
        local pct = math.clamp((mouseX - trackPos) / trackWidth, 0, 1)
        updateSlider(pct * 0.9)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)

-- ═══════════════════════════════════════
--           ЛОГИКА CustomBG
-- ═══════════════════════════════════════
local bgImage = nil

ApplyBgBtn.MouseButton1Click:Connect(function()
    local id = BgInput.Text:match("%d+")
    if id then
        if not bgImage then
            bgImage = Instance.new("ImageLabel")
            bgImage.Size = UDim2.new(1, 0, 1, 0)
            bgImage.BackgroundTransparency = 1
            bgImage.ScaleType = Enum.ScaleType.Crop
            bgImage.ZIndex = 1
            bgImage.Parent = Main
            makeCorner(bgImage, 14)
        end
        bgImage.Image = "rbxassetid://" .. id
        tween(ApplyBgBtn, { BackgroundColor3 = Color3.fromRGB(30, 80, 50) }, 0.15)
        task.wait(0.5)
        tween(ApplyBgBtn, { BackgroundColor3 = Color3.fromRGB(50, 46, 64) }, 0.15)
    end
end)

-- ═══════════════════════════════════════
--           НАВИГАЦИЯ
-- ═══════════════════════════════════════
local currentPage = "home"

local function setPage(page)
    currentPage = page
    PageHome.Visible = page == "home"
    PageScripts.Visible = page == "scripts"
    SettingsOverlay.Visible = false

    FooterTitle.Text = page:upper()

    -- Подсветка активной кнопки
    tween(BtnHome, { BackgroundColor3 = page == "home" and Color3.fromRGB(45, 42, 60) or Color3.fromRGB(30, 28, 38) }, 0.15)
    tween(BtnScripts, { BackgroundColor3 = page == "scripts" and Color3.fromRGB(45, 42, 60) or Color3.fromRGB(30, 28, 38) }, 0.15)
end

BtnHome.MouseButton1Click:Connect(function() setPage("home") end)
BtnScripts.MouseButton1Click:Connect(function() setPage("scripts") end)

BtnSettings.MouseButton1Click:Connect(function()
    local isOpen = SettingsOverlay.Visible
    SettingsOverlay.Visible = not isOpen
    FooterTitle.Text = not isOpen and "SETTINGS" or currentPage:upper()
    tween(BtnSettings, { BackgroundColor3 = not isOpen and Color3.fromRGB(45, 42, 60) or Color3.fromRGB(30, 28, 38) }, 0.15)
end)

CloseSettingsBtn.MouseButton1Click:Connect(function()
    SettingsOverlay.Visible = false
    FooterTitle.Text = currentPage:upper()
    tween(BtnSettings, { BackgroundColor3 = Color3.fromRGB(30, 28, 38) }, 0.15)
end)

-- ═══════════════════════════════════════
--           HOVER эффекты кнопок
-- ═══════════════════════════════════════
for _, btn in ipairs({BtnHome, BtnScripts, BtnSettings}) do
    btn.MouseEnter:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(45, 42, 60) then
            tween(btn, { BackgroundColor3 = Color3.fromRGB(38, 35, 50) }, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(45, 42, 60) then
            tween(btn, { BackgroundColor3 = Color3.fromRGB(30, 28, 38) }, 0.15)
        end
    end)
end

-- ═══════════════════════════════════════
--           DRAG (перетаскивание окна)
-- ═══════════════════════════════════════
local dragging, dragStart, startPos

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ═══════════════════════════════════════
--           АНИМАЦИЯ ПОЯВЛЕНИЯ
-- ═══════════════════════════════════════
Main.BackgroundTransparency = 1
Main.Size = UDim2.new(0, 640, 0, 480)
tween(Main, { BackgroundTransparency = 0, Size = UDim2.new(0, 680, 0, 520) }, 0.35, Enum.EasingStyle.Back)

setPage("home")