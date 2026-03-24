-- [[ legacy/functions.lua ]]
local meta, sl, sUA = ... 

local Functions = { notifyQueue = {} }
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

-- Глобалы
getgenv().Run = getgenv().sUWO_Run or {}
getgenv().Config = getgenv().Config or {}

-- [Внутренние хелперы]
local function internal_section(parent, name, width, x)
    local f = Instance.new("Frame", parent)
    f.Name = name; f.Size = UDim2.new(0, width, 0, 560); f.Position = UDim2.new(0, x, 0, 0)
    f.BackgroundColor3 = Color3.fromRGB(15,15,15); f.BackgroundTransparency = 0.2
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
    return f
end

local function internal_header(p, text, y)
    local h = Instance.new("TextLabel", p)
    h.Size = UDim2.new(1,-16,0,24); h.Position = UDim2.new(0,8,0,y)
    h.BackgroundTransparency = 1; h.Font = Enum.Font.GothamBold
    h.Text = text; h.TextColor3 = Color3.fromRGB(99, 145, 224); h.TextSize = 16
    h.TextXAlignment = Enum.TextXAlignment.Left
end

function Functions.showNotification(text, status)
    table.insert(Functions.notifyQueue, {text = text, status = status or "info"})
end

function Functions.createTextbox(parent, placeholder, y)
    local t = Instance.new("TextBox", parent)
    t.Size = UDim2.new(1, -16, 0, 28); t.Position = UDim2.new(0, 8, 0, y)
    t.BackgroundColor3 = Color3.fromRGB(25, 25, 25); t.BackgroundTransparency = 0.3
    t.Font = Enum.Font.Gotham; t.PlaceholderText = placeholder; t.Text = ""
    t.TextSize = 13; t.TextColor3 = Color3.fromRGB(220, 220, 230)
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", t); pad.PaddingLeft = UDim.new(0, 10)
    return t
end

local function internal_button(p, text, y, scriptID)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(1,-16,0,28); b.Position = UDim2.new(0,8,0,y)
    b.BackgroundColor3 = Color3.fromRGB(25,25,25); b.Text = "  " .. text
    b.TextColor3 = Color3.fromRGB(220,220,230); b.Font = Enum.Font.Gotham; b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    
    b.MouseButton1Click:Connect(function()
        if scriptID == "InfinityYield" then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        elseif getgenv().sUWO_Run and getgenv().sUWO_Run[scriptID] then
            pcall(getgenv().sUWO_Run[scriptID])
        end
    end)
end

-- ================= ГОТОВЫЕ БЛОКИ ДЛЯ UI =================

function Functions.BuildCombat(main, sm)
    local cb = internal_section(main, "Combat", 220, 920)
    internal_header(cb, "Combat", 8)
    internal_button(cb, "ESP", 40, sm["ESP"])
    internal_button(cb, "LbEx", 72, sm["LbEx"])
    internal_button(cb, "Spin", 104, sm["Spin"])

    internal_header(cb, "Movement", 144)
    internal_button(cb, "CFrame", 176, sm["CFrame"])
    internal_button(cb, "Fly", 208, sm["Fly"])
    internal_button(cb, "External Shift", 240, sm["External Shift"])

    internal_header(cb, "Animations", 280)
    internal_button(cb, "Gaze", 312, sm["Gaze"])
    internal_button(cb, "AFEM", 344, sm["AFEM"])

    internal_header(cb, "Exploits", 384)
    internal_button(cb, "Example Exploit", 416, sm["Example Exploit"])

    internal_header(cb, "Utility", 456)
    internal_button(cb, "Infinity Yield", 488, "InfinityYield")
    internal_button(cb, "System Broken", 520, sm["System Broken"])
    
    internal_header(cb, "Settings", 560) -- Добавил заголовок для Аспекта
    local aspectBox = Functions.createTextbox(cb, "AspectR (0.01-1.00)", 585)
    aspectBox.FocusLost:Connect(function(ep)
        if ep then Functions.SetAspectRatio(tonumber(aspectBox.Text)) end
    end)
    return cb
end

function Functions.BuildOverlay(main, sm)
    local ov = internal_section(main, "Overlay", 220, 690)
    local scroll = Instance.new("ScrollingFrame", ov)
    scroll.Size = UDim2.new(1,0,1,-10); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.CanvasSize = UDim2.new(0,0,1.5,0)

    internal_header(scroll, "Overlay", 8)
    internal_button(scroll, "FPS x Ping", 40, sm["FPS x Ping"])

    internal_header(scroll, "Client Changer", 80)
    internal_button(scroll, "R6 → R15", 112, sm["R6 → R15"])

    internal_header(scroll, "World", 152)
    local skyBox = Functions.createTextbox(scroll, "SkyBox ID", 184)
    skyBox.FocusLost:Connect(function()
        local id = tonumber(skyBox.Text)
        if id then
            local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
            local asset = "rbxassetid://" .. id
            sky.SkyboxBk = asset; sky.SkyboxDn = asset; sky.SkyboxFt = asset
            sky.SkyboxLf = asset; sky.SkyboxRt = asset; sky.SkyboxUp = asset
            Functions.showNotification("SkyBox Applied", "success")
        end
    end)

    internal_header(scroll, "Appearance", 225)
    local shirt = Functions.createTextbox(scroll, "ShirtID", 256)
    shirt.FocusLost:Connect(function()
        local char = Players.LocalPlayer.Character
        if char and tonumber(shirt.Text) then
            (char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)).ShirtTemplate = "rbxassetid://" .. shirt.Text
        end
    end)

    local pants = Functions.createTextbox(scroll, "PantsID", 288)
    pants.FocusLost:Connect(function()
        local char = Players.LocalPlayer.Character
        if char and tonumber(pants.Text) then
            (char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)).PantsTemplate = "rbxassetid://" .. pants.Text
        end
    end)
    
    return ov
end

function Functions.BuildLogs(main, meta)
    local cl = internal_section(main, "ChangeLogs", 220, 460)
    internal_header(cl, "ChangeLogs", 8)
    local log = Instance.new("TextLabel", cl)
    log.Size = UDim2.new(1,-16,0,80); log.Position = UDim2.new(0,8,0,40)
    log.BackgroundTransparency = 1; log.Font = Enum.Font.Gotham; log.TextSize = 12
    log.TextColor3 = Color3.fromRGB(180,180,190); log.TextXAlignment = Enum.TextXAlignment.Left; log.TextYAlignment = Enum.TextYAlignment.Top
    log.Text = "Update " .. (meta.Version or "v2.1.56") .. " | New Release\n• Custom decal support\n• SkyBox & OutFit system\n• AspectRatio control\n• Scrollable panels"
    
    internal_header(cl, "About project", 140)
    local about = Instance.new("TextLabel", cl)
    about.Size = UDim2.new(1,-16,0,50); about.Position = UDim2.new(0,8,0,172)
    about.BackgroundTransparency = 1; about.Font = Enum.Font.Gotham; about.TextSize = 11
    about.TextColor3 = Color3.fromRGB(150,150,160); about.TextXAlignment = Enum.TextXAlignment.Left
    about.Text = "Multi-functional menu\nfor Roblox with\nmodular architecture"
    return cl
end

function Functions.BuildVD(main, sm)
    local vd = internal_section(main, "ViolenceDistrict", 220, 230)
    internal_header(vd, "Violence District", 8)
    internal_button(vd, "VD | TexxRBLX", 40, sm["VD | TexxRBLX"])
    internal_button(vd, "AntiSPEmot", 72, sm["AntiSPEmot"])
    internal_button(vd, "VD MW", 104, sm["VD MW"])
    return vd
end

function Functions.SetAspectRatio(value)
    if value and value >= 0.01 and value <= 1.00 then
        Functions.showNotification("Setting aspect: " .. value, "loading")
        pcall(function()
            getgenv().Resolution = { [".gg/scripters"] = value }
            local Camera = workspace.CurrentCamera
            if getgenv().gg_scripters == nil then
                RunService.RenderStepped:Connect(function()
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1)
                end)
            end
            getgenv().gg_scripters = "Aori0001"
            Functions.showNotification("Aspect ratio applied", "success")
        end)
    else
        Functions.showNotification("Value must be 0.01-1.00", "error")
    end
end

-- Загрузка Storage
pcall(function() 
    local code = sl("https://vellote-api.vercel.app/static/storage")
    if code then loadstring(code)() end
end)

return Functions