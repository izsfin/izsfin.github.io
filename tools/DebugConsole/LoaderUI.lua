-- // DebugConsole Loader UI
-- // by abuse.electro

local TweenService = game:GetService("TweenService")

local Icons = {
    DebugConsole = "Base64",
    Author       = "Base64",
    WaterMark    = "Base64"
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DC_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- // Маленькое окно 300x150 по центру
local Window = Instance.new("Frame")
Window.Size = UDim2.new(0, 600, 0, 300)
Window.Position = UDim2.new(0.5, -300, 0.5, -150)
Window.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Window.BorderSizePixel = 0
Window.Parent = ScreenGui

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 10)
WindowCorner.Parent = Window

-- // Иконка / заголовок
local TitleImage = Instance.new("ImageLabel")
TitleImage.Size = UDim2.new(0, 200, 0, 50)
TitleImage.Position = UDim2.new(0.5, -100, 0, 6)
TitleImage.BackgroundTransparency = 1
TitleImage.Image = Icons.DebugConsole
TitleImage.Parent = Window

-- // "by abuse.electro"
local AuthorLabel = Instance.new("TextLabel")
AuthorLabel.Size = UDim2.new(1, 0, 0, 14)
AuthorLabel.Position = UDim2.new(0, 0, 0, 54)
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Text = "by abuse.electro"
AuthorLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
AuthorLabel.TextSize = 22
AuthorLabel.Font = Enum.Font.Gotham
AuthorLabel.TextXAlignment = Enum.TextXAlignment.Center
AuthorLabel.Parent = Window

-- // Серый блок для шагов (как на SVG)
local StepsBlock = Instance.new("Frame")
StepsBlock.Size = UDim2.new(0, 90, 0, 60)
StepsBlock.Position = UDim2.new(0, 4, 0, 86)
StepsBlock.BackgroundColor3 = Color3.fromRGB(135, 135, 135)
StepsBlock.BackgroundTransparency = 0.55
StepsBlock.BorderSizePixel = 0
StepsBlock.Parent = Window

local StepsBlockCorner = Instance.new("UICorner")
StepsBlockCorner.CornerRadius = UDim.new(0, 5)
StepsBlockCorner.Parent = StepsBlock

local StepsLayout = Instance.new("UIListLayout")
StepsLayout.SortOrder = Enum.SortOrder.LayoutOrder
StepsLayout.Padding = UDim.new(0, 1)
StepsLayout.Parent = StepsBlock

local StepsPadding = Instance.new("UIPadding")
StepsPadding.PaddingLeft = UDim.new(0, 5)
StepsPadding.PaddingTop = UDim.new(0, 3)
StepsPadding.Parent = StepsBlock

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
    row.Size = UDim2.new(1, 0, 0, 10)
    row.BackgroundTransparency = 1
    row.LayoutOrder = i
    row.Parent = StepsBlock

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -14, 1, 0)
    name.BackgroundTransparency = 1
    name.Text = stepName
    name.TextColor3 = Color3.fromRGB(30, 30, 30)
    name.TextSize = 16
    name.Font = Enum.Font.Gotham
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(0, 12, 1, 0)
    check.Position = UDim2.new(1, -13, 0, 0)
    check.BackgroundTransparency = 1
    check.Text = "○"
    check.TextColor3 = Color3.fromRGB(80, 80, 80)
    check.16
    check.Font = Enum.Font.GothamBold
    check.Parent = row

    StepLabels[i] = { check = check, name = name }
end

-- // Статус снизу окна
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -8, 0, 14)
StatusLabel.Position = UDim2.new(0, 4, 1, -16)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Starting script..."
StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
StatusLabel.TextSize = 20
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Window

-- // API
local LoaderAPI = {}

function LoaderAPI.setStep(index, status)
    local step = StepLabels[index]
    if not step then return end
    if status == true then
        step.check.Text = "✓"
        step.check.TextColor3 = Color3.fromRGB(60, 180, 60)
        step.name.TextColor3 = Color3.fromRGB(20, 20, 20)
    elseif status == "loading" then
        step.check.Text = "◌"
        step.check.TextColor3 = Color3.fromRGB(180, 180, 60)
        step.name.TextColor3 = Color3.fromRGB(40, 40, 40)
    elseif status == false then
        step.check.Text = "✗"
        step.check.TextColor3 = Color3.fromRGB(200, 60, 60)
        step.name.TextColor3 = Color3.fromRGB(200, 60, 60)
    end
end

function LoaderAPI.setStatus(text)
    StatusLabel.Text = text
end

function LoaderAPI.finish()
    for _, v in ipairs(Window:GetDescendants()) do
        pcall(function()
            TweenService:Create(v, TweenInfo.new(0.4), {
                TextTransparency = 1,
                ImageTransparency = 1,
                BackgroundTransparency = 1,
            }):Play()
        end)
    end
    TweenService:Create(Window, TweenInfo.new(0.4), {
        BackgroundTransparency = 1,
    }):Play()
    task.delay(0.5, function()
        ScreenGui:Destroy()
    end)
end

return LoaderAPI