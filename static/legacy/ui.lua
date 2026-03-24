-- [[ legacy/ui.lua ]]
local meta, sm, func, sUA, bu, r, hl, hlv2 = ... 

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ================= BASE GUI =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = meta.Name or "nixumenu"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000000000
screenGui.Enabled = false
screenGui.Parent = CoreGui

local overlay = Instance.new("Frame", screenGui)
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
overlay.BackgroundTransparency = 1
overlay.ZIndex = 1

-- Контейнер уведомлений
local notifContainer = Instance.new("Frame", screenGui)
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0,320,0,500)
notifContainer.Position = UDim2.new(1,-330,1,-510)
notifContainer.BackgroundTransparency = 1

local notifLayout = Instance.new("UIListLayout", notifContainer)
notifLayout.Padding = UDim.new(0,8)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

-- Цикл обработки уведомлений из func
task.spawn(function()
    while true do
        if #func.notifyQueue > 0 then
            local n = table.remove(func.notifyQueue, 1)
            -- Здесь можно вызвать визуальную функцию уведомления
            -- Для теста выводим в консоль
            print("[" .. n.status .. "]: " .. n.text)
        end
        task.wait(0.1)
    end
end)

-- ================= MAIN FRAME =================
local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0,1220,0,580)
main.Position = UDim2.new(0.5,-610,0.5,-290)
main.BackgroundTransparency = 1
main.ZIndex = 3

-- ================= СБОРКА ИНТЕРФЕЙСА =================

-- 1. Секция Лого (Nixu)
local nixu = Instance.new("Frame", main)
nixu.Size = UDim2.new(0,220,0,560)
nixu.BackgroundColor3 = Color3.fromRGB(20,20,20)
nixu.BackgroundTransparency = 0.1
Instance.new("UICorner", nixu).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", nixu)
title.Size = UDim2.new(1,0,0,50)
title.Position = UDim2.new(0,0,0,20)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "jessi Legacy"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 24

local version = Instance.new("TextLabel", nixu)
version.Size = UDim2.new(1,0,0,20)
version.Position = UDim2.new(0,0,0,50)
version.BackgroundTransparency = 1
version.Font = Enum.Font.Gotham
version.Text = meta.Version or "v2.1.56"
version.TextColor3 = Color3.fromRGB(100,100,110)
version.TextSize = 12

-- 2. Сборка всех остальных секций через func
func.BuildVD(main, sm)        -- Violence District (x=230)
func.BuildLogs(main, meta)    -- ChangeLogs (x=460)
func.BuildOverlay(main, sm)   -- Overlay (x=690)
func.BuildCombat(main, sm)    -- Combat (x=920)

-- ================= TOGGLE LOGIC =================
local open = false
local cooldown = false

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.BackSlash and not cooldown then
        cooldown = true
        open = not open
        
        if open then
            screenGui.Enabled = true
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
        else
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.delay(0.3, function() screenGui.Enabled = false end)
        end
        
        task.wait(0.4)
        cooldown = false
    end
end)

func.showNotification("System ready!", "success")