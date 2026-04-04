-- // DebugConsole Loader UI
-- // by abuse.electro

local Players   = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Icons = {
    DebugConsole = "Base64", -- rbxassetid:// или base64
    Author       = "Base64",
    WaterMark    = "Base64"
}

-- // ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DC_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- // Фон
local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Background.BorderSizePixel = 0
Background.Parent = ScreenGui

-- // Контейнер по центру
local Container = Instance.new("Frame")
Container.Size = UDim2.new(0, 280, 0, 200)
Container.Position = UDim2.new(0.5, -140, 0.5, -100)
Container.BackgroundTransparency = 1
Container.Parent = Background

-- // Иконка DebugConsole (текст/изображение)
local TitleImage = Instance.new("ImageLabel")
TitleImage.Size = UDim2.new(0, 220, 0, 60)
TitleImage.Position = UDim2.new(0.5, -110, 0, 0)
TitleImage.BackgroundTransparency = 1
TitleImage.Image = Icons.DebugConsole -- base64 или rbxassetid
TitleImage.Parent = Container

-- // "by abuse.electro"
local AuthorLabel = Instance.new("TextLabel")
AuthorLabel.Size = UDim2.new(1, 0, 0, 20)
AuthorLabel.Position = UDim2.new(0, 0, 0, 65)
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Text = "by abuse.electro"
AuthorLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
AuthorLabel.TextSize = 13
AuthorLabel.Font = Enum.Font.Gotham
AuthorLabel.TextXAlignment = Enum.TextXAlignment.Center
AuthorLabel.Parent = Container

-- // Шаги загрузки
local StepsContainer = Instance.new("Frame")
StepsContainer.Size = UDim2.new(1, 0, 0, 100)
StepsContainer.Position = UDim2.new(0, 0, 0, 95)
StepsContainer.BackgroundTransparency = 1
StepsContainer.Parent = Container

local StepsLayout = Instance.new("UIListLayout")
StepsLayout.SortOrder = Enum.SortOrder.LayoutOrder
StepsLayout.Padding = UDim.new(0, 4)
StepsLayout.Parent = StepsContainer

local Steps = {
    "Loading Executor",
    "Loading Console",
    "Loading WaterMark",
    "Loading Modules",
    "Loading UI",
}

local StepLabels = {}

for i, stepName in ipairs(Steps) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    row.LayoutOrder = i
    row.Parent = StepsContainer

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -24, 1, 0)
    name.BackgroundTransparency = 1
    name.Text = stepName
    name.TextColor3 = Color3.fromRGB(180, 180, 180)
    name.TextSize = 12
    name.Font = Enum.Font.Gotham
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(0, 20, 1, 0)
    check.Position = UDim2.new(1, -20, 0, 0)
    check.BackgroundTransparency = 1
    check.Text = "○"
    check.TextColor3 = Color3.fromRGB(100, 100, 100)
    check.TextSize = 12
    check.Font = Enum.Font.GothamBold
    check.TextXAlignment = Enum.TextXAlignment.Right
    check.Parent = row

    StepLabels[i] = { row = row, check = check, name = name }
end

-- // Статус снизу
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 16)
StatusLabel.Position = UDim2.new(0, 0, 1, -16)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Starting script..."
StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = Container

-- // Watermark снизу экрана
local WaterMark = Instance.new("ImageLabel")
WaterMark.Size = UDim2.new(0, 120, 0, 30)
WaterMark.Position = UDim2.new(0, 8, 1, -38)
WaterMark.BackgroundTransparency = 1
WaterMark.Image = Icons.WaterMark
WaterMark.Parent = Background

-- // API лоадера
local LoaderAPI = {}

-- Отмечает шаг как выполненный
function LoaderAPI.setStep(index, status)
    local step = StepLabels[index]
    if not step then return end

    if status == true then
        step.check.Text = "✓"
        step.check.TextColor3 = Color3.fromRGB(100, 200, 100)
        step.name.TextColor3 = Color3.fromRGB(220, 220, 220)
    elseif status == "loading" then
        step.check.Text = "◌"
        step.check.TextColor3 = Color3.fromRGB(200, 200, 100)
        step.name.TextColor3 = Color3.fromRGB(200, 200, 200)
    elseif status == false then
        step.check.Text = "✗"
        step.check.TextColor3 = Color3.fromRGB(200, 80, 80)
        step.name.TextColor3 = Color3.fromRGB(200, 80, 80)
    end
end

-- Обновляет текст статуса снизу
function LoaderAPI.setStatus(text)
    StatusLabel.Text = text
end

-- Закрывает лоадер с fade out
function LoaderAPI.finish()
    local tween = TweenService:Create(
        Background,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 }
    )
    -- Фейдим все дочерние элементы
    for _, v in ipairs(Background:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("ImageLabel") or v:IsA("Frame") then
            pcall(function()
                TweenService:Create(v, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1,
                    TextTransparency = 1,
                    ImageTransparency = 1,
                }):Play()
            end)
        end
    end
    tween:Play()
    tween.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end

return LoaderAPI