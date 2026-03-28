local Config = {
    -- Клавиша для открытия/закрытия меню
    OpenClose = Enum.KeyCode.BackSlash, 
    
    -- Цвета в формате RGB строк (для работы Color Highlight в VSCode)
    Colors = {
        Main = "143, 255, 248",      -- Основной бирюзовый
        Secondary = "61, 117, 114",   -- Темный бирюзовый (для градиента)
        Background = "20, 20, 20",    -- Цвет фона панелей
        Stroke = "100, 100, 100",     -- Цвет обводок
	
        Loading = "87, 247, 237",
        Success = "117, 149, 201",
        Error = "32, 107, 102",
        Info = "31, 204, 193"
    }
}

-- Функция-парсер (превращает "0,0,0" в Color3)
local function parseColor(str)
    local r, g, b = str:match("(%d+),%s*(%d+),%s*(%d+)")
    return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
end

-- Переменные для быстрого доступа к цветам в коде
local MainColor = parseColor(Config.Colors.Main)
local SecColor = parseColor(Config.Colors.Secondary)
local BgColor = parseColor(Config.Colors.Background)
local StrokeColor = parseColor(Config.Colors.Stroke)


local SCRIPT_MAP = {
    ["VD | TexxRBLX"] = "VDTexRBLX",
    ["AntiSPEmot"] = "DisableStopEmote",
    ["VD MW"] = "MoonWalk",
    ["WhakizashiX"] = "WhakazhiHubX",
    ["Dara Hub"] = "DaraHub",
    ["Kron Hub"] = "KronHub",
    ["Vertex"] = "VertexMM2",
    ["XHub"] = "XHubMM2",
    ["ODH"] = "ODHMM2",
    
    -- Overlay
    ["FPS x Ping"] = "FPSxPing",
    ["R6 → R15"] = "R6toR15",
    
    -- Combat
    ["ESP"] = "WAESP",
    ["LbEx"] = "LimbExtender_rewrite",
    ["Spin"] = "Spin",
    ["CFrame"] = "Cframe",
    ["Fly"] = "Fly",
    ["External Shift"] = "External_Shift",
    ["Gaze"] = "Gaze",
    ["AFEM"] = "afem",
    ["Example Exploit"] = "Exploit",
    ["System Broken"] = "SysBroken"
}
local Run
local notifyQueue = {}
local function showNotification(text, status) table.insert(notifyQueue, {text = text, status = status or "info"}) end
 showNotification("Loading jessi Legacy...", "loading")

getgenv().Run = getgenv().Run or {}
getgenv().Config = getgenv().Config or {} -- Вот этой строки у тебя не хватало!

-- 2. Теперь, когда Config существует, можно в него записывать данные из SCRIPT_MAP
for k, v in pairs(SCRIPT_MAP) do
    getgenv().Config[v] = true
end

-- 3. Загружаем внешние модули
pcall(function()
    loadstring(game:HttpGet("https://vellote-api.vercel.app/base/storage"))()
    Run = getgenv().Run
    showNotification("Modules loaded successfully", "success")
end)

-- ================= SERVICES =================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local gui = CoreGui

-- ================= GUI =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "nixumenu"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000000000
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Enabled = false
screenGui.Parent = gui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
overlay.BackgroundTransparency = 0
overlay.ZIndex = 1
overlay.Parent = screenGui

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting


local notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0,320,0,500)
notifContainer.Position = UDim2.new(1,-330,1,-510)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 999999
notifContainer.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0,8)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Parent = notifContainer

local function createNotification(text, status)
    local colors = {
        loading = Color3.fromRGB(87, 247, 237),
        success = Color3.fromRGB(117, 149, 201),
        error = Color3.fromRGB(32, 107, 102),
        info = Color3.fromRGB(31, 204, 193)
    }
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1,0,0,60)
    notif.BackgroundColor3 = Color3.fromRGB(20,20,20)
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.Position = UDim2.new(0,330,0,0)
    notif.Parent = notifContainer
    
    local corner = Instance.new("UICorner",notif)
    corner.CornerRadius = UDim.new(0,10)
    
    local stroke = Instance.new("UIStroke",notif)
    stroke.Color = colors[status] or colors.info
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0,40,1,0)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBold
    icon.Text = status == "success" and "✓" or status == "error" and "✗" or status == "loading" and "⟳" or "i"
    icon.TextSize = 24
    icon.TextColor3 = colors[status] or colors.info
    icon.Parent = notif
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-50,1,0)
    label.Position = UDim2.new(0,45,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(220,220,230)
    label.Parent = notif
    
    -- Slide in
    TweenService:Create(notif,TweenInfo.new(0.3,Enum.EasingStyle.Back),{
        Position = UDim2.new(0,0,0,0)
    }):Play()
    
    -- Auto remove after 3 seconds
    task.delay(3,function()
        TweenService:Create(notif,TweenInfo.new(0.3),{
            Position = UDim2.new(0,330,0,0),
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(label,TweenInfo.new(0.3),{
            TextTransparency = 1
        }):Play()
        TweenService:Create(icon,TweenInfo.new(0.3),{
            TextTransparency = 1
        }):Play()
        TweenService:Create(stroke,TweenInfo.new(0.3),{
            Transparency = 1
        }):Play()
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- Process notification queue
task.spawn(function()
    while true do
        if #notifyQueue > 0 then
            local notif = table.remove(notifyQueue, 1)
            createNotification(notif.text, notif.status)
            task.wait(0.2)
        end
        task.wait(0.1)
    end
end)

-- ================= MAIN =================
local main = Instance.new("Frame")
main.Size = UDim2.new(0,1220,0,580)
main.Position = UDim2.new(0.5,-610,0.5,-290)
main.BackgroundTransparency = 1
main.ZIndex = 3
main.Parent = screenGui

-- ================= UI HELPERS =================
local function createSection(name,width,x)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.new(0,width,0,560)
    f.Position = UDim2.new(0,x,0,0)
    f.BackgroundColor3 = Color3.fromRGB(15,15,15)
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.ClipsDescendants = false
    f.Parent = main

    local corner = Instance.new("UICorner",f)
    corner.CornerRadius = UDim.new(0,14)
    
    local stroke = Instance.new("UIStroke",f)
    stroke.Color = Color3.fromRGB(100,100,100)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    
    return f
end

local function header(p,text,y)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1,-16,0,24)
    h.Position = UDim2.new(0,8,0,y)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.Text = text
    h.TextSize = 16
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.TextColor3 = Color3.fromRGB(143, 255, 248)
    h.Parent = p
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0,60,0,2)
    line.Position = UDim2.new(0,8,0,y+26)
    line.BackgroundColor3 = Color3.fromRGB(143, 255, 248)
    line.BorderSizePixel = 0
    line.Parent = p
end

local function button(p,text,y,scriptName)
    local b = Instance.new("TextButton")
    b.Name = text
    b.Size = UDim2.new(1,-16,0,28)
    b.Position = UDim2.new(0,8,0,y)
    b.BackgroundColor3 = Color3.fromRGB(25,25,25)
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.Text = "  " .. text
    b.TextSize = 13
    b.TextWrapped = true
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextColor3 = Color3.fromRGB(220,220,230)
    b.Parent = p

    local corner = Instance.new("UICorner",b)
    corner.CornerRadius = UDim.new(0,8)
    
    local stroke = Instance.new("UIStroke",b)
    stroke.Color = Color3.fromRGB(143, 255, 248)
    stroke.Transparency = 0.8
    stroke.Thickness = 0.2
    
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{
            BackgroundColor3 = Color3.fromRGB(35,35,35),
            BackgroundTransparency = 0.1
        }):Play()
        TweenService:Create(stroke,TweenInfo.new(0.15),{
            Transparency = 0.3
        }):Play()
    end)
    
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{
            BackgroundColor3 = Color3.fromRGB(25,25,25),
            BackgroundTransparency = 0.3
        }):Play()
        TweenService:Create(stroke,TweenInfo.new(0.15),{
            Transparency = 0.8
        }):Play()
    end)
    
    b.MouseButton1Click:Connect(function()
        if scriptName == "InfinityYield" then
            showNotification("Loading Infinity Yield...", "loading")
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
                showNotification("Infinity Yield loaded", "success")
            end)
        elseif getgenv().Run and scriptName and getgenv().Run[scriptName] then
            showNotification("Executing " .. text .. "...", "loading")
            local success, err = pcall(function()
                getgenv().Run[scriptName]()
            end)
            if success then
                showNotification(text .. " executed", "success")
            else
                showNotification("Error: " .. tostring(err), "error")
            end
        else
            showNotification("Function not found: " .. (scriptName or "unknown"), "error")
        end
    end)
    
    return b
end

local function textbox(p,placeholder,y)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1,-16,0,28)
    t.Position = UDim2.new(0,8,0,y)
    t.BackgroundColor3 = Color3.fromRGB(25,25,25)
    t.BackgroundTransparency = 0.3
    t.BorderSizePixel = 0
    t.Font = Enum.Font.Gotham
    t.PlaceholderText = placeholder
    t.Text = ""
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = Color3.fromRGB(220,220,230)
    t.Parent = p

    local pad = Instance.new("UIPadding",t)
    pad.PaddingLeft = UDim.new(0,10)

    local corner = Instance.new("UICorner",t)
    corner.CornerRadius = UDim.new(0,8)
    
    local stroke = Instance.new("UIStroke",t)
    stroke.Color = Color3.fromRGB(100,100,100)
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    
    return t
end

-- ================= SECTIONS =================

-- NL Logo with Decal
local nixu = createSection("Nixu",220,0)
nixu.BackgroundTransparency = 0.1
nixu.BackgroundColor3 = Color3.fromRGB(1,1,1)


local version = Instance.new("TextLabel")
version.Size = UDim2.new(1,-20,0,20)
version.Position = UDim2.new(0,10,1,-30)
version.BackgroundTransparency = 1
version.Font = Enum.Font.Gotham
version.Text = "v2.1.56 | Release Build"
version.TextSize = 11
version.TextXAlignment = Enum.TextXAlignment.Left
version.TextColor3 = Color3.fromRGB(100,100,110)
version.Parent = nixu

-- Violence District
local vd = createSection("ViolenceDistrict",220,230)
header(vd,"Violence District",8)
button(vd,"VD | TexxRBLX",40, SCRIPT_MAP["VD | TexxRBLX"])
button(vd,"AntiSPEmot",72, SCRIPT_MAP["AntiSPEmot"])
button(vd,"VD MW",104, SCRIPT_MAP["VD MW"])

header(vd,"Evade",144)
button(vd,"WhakizashiX",176, SCRIPT_MAP["WhakizashiX"])
button(vd,"Dara Hub",208, SCRIPT_MAP["Dara Hub"])

header(vd,"Lumber Tycoon 2",248)
button(vd,"Kron Hub",280, SCRIPT_MAP["Kron Hub"])

header(vd,"MM2",320)
button(vd,"Vertex",352, SCRIPT_MAP["Vertex"])
button(vd,"XHub",384, SCRIPT_MAP["XHub"])
button(vd,"ODH",416, SCRIPT_MAP["ODH"])

-- ChangeLogs
local cl = createSection("ChangeLogs",220,460)
header(cl,"ChangeLogs",8)

local log = Instance.new("TextLabel")
log.Size = UDim2.new(1,-16,0,80)
log.Position = UDim2.new(0,8,0,40)
log.BackgroundTransparency = 1
log.Font = Enum.Font.Gotham
log.Text = "Update 2.1.56 | New Release\n• Custom decal support\n• SkyBox & OutFit system\n• AspectRatio control\n• Scrollable panels"
log.TextSize = 12
log.TextXAlignment = Enum.TextXAlignment.Left
log.TextYAlignment = Enum.TextYAlignment.Top
log.TextColor3 = Color3.fromRGB(180,180,190)
log.Parent = cl

header(cl,"About project",140)

local about = Instance.new("TextLabel")
about.Size = UDim2.new(1,-16,0,50)
about.Position = UDim2.new(0,8,0,172)
about.BackgroundTransparency = 1
about.Font = Enum.Font.Gotham
about.Text = "Multi-functional menu\nfor Roblox with\nmodular architecture"
about.TextSize = 11
about.TextXAlignment = Enum.TextXAlignment.Left
about.TextYAlignment = Enum.TextYAlignment.Top
about.TextColor3 = Color3.fromRGB(150,150,160)
about.Parent = cl

header(cl,"Contact",240)

local contact = Instance.new("TextLabel")
contact.Size = UDim2.new(1,-16,0,30)
contact.Position = UDim2.new(0,8,0,272)
contact.BackgroundTransparency = 1
contact.Font = Enum.Font.Gotham
contact.Text = "Discord | in dev"
contact.TextSize = 11
contact.TextXAlignment = Enum.TextXAlignment.Left
contact.TextYAlignment = Enum.TextYAlignment.Top
contact.TextColor3 = Color3.fromRGB(143, 255, 248)
contact.Parent = cl

-- Overlay with Scrolling
local ov = createSection("Overlay",220,690)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,0,1,0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(143, 255, 248)
scrollFrame.ScrollBarImageTransparency = 0.8
scrollFrame.CanvasSize = UDim2.new(0,0,1.4,0)
scrollFrame.Parent = ov

header(scrollFrame,"Overlay",8)
button(scrollFrame,"FPS x Ping",40, SCRIPT_MAP["FPS x Ping"])

header(scrollFrame,"Client Changer",80)
button(scrollFrame,"R6 → R15",112, SCRIPT_MAP["R6 → R15"])

header(scrollFrame,"SkyBox",152)
local skyboxInput = textbox(scrollFrame,"SkyBox ID",184)
skyboxInput.FocusLost:Connect(function()
    local skyboxId = tonumber(skyboxInput.Text)
    if skyboxId then
        showNotification("Applying SkyBox...", "loading")
        pcall(function()
            local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
            local assetUrl = "rbxassetid://" .. skyboxId
            sky.SkyboxBk = assetUrl
            sky.SkyboxDn = assetUrl
            sky.SkyboxFt = assetUrl
            sky.SkyboxLf = assetUrl
            sky.SkyboxRt = assetUrl
            sky.SkyboxUp = assetUrl
            showNotification("SkyBox applied", "success")
        end)
    else
        showNotification("Invalid SkyBox ID", "error")
    end
end)

header(scrollFrame,"OutFit",224)
local shirtInput = textbox(scrollFrame,"ShirtID",256)
local pantsInput = textbox(scrollFrame,"PantsID",288)

shirtInput.FocusLost:Connect(function()
    local shirtId = tonumber(shirtInput.Text)
    if shirtId then
        showNotification("Applying Shirt...", "loading")
        pcall(function()
            local char = plr.Character
            if char then
                local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
                shirt.ShirtTemplate = "rbxassetid://" .. shirtId
                showNotification("Shirt applied", "success")
            end
        end)
    else
        showNotification("Invalid Shirt ID", "error")
    end
end)

pantsInput.FocusLost:Connect(function()
    local pantsId = tonumber(pantsInput.Text)
    if pantsId then
        showNotification("Applying Pants...", "loading")
        pcall(function()
            local char = plr.Character
            if char then
                local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
                pants.PantsTemplate = "rbxassetid://" .. pantsId
                showNotification("Pants applied", "success")
            end
        end)
    else
        showNotification("Invalid Pants ID", "error")
    end
end)

-- Combat
local cb = createSection("Combat",220,920)
header(cb,"Combat",8)
button(cb,"ESP",40, SCRIPT_MAP["ESP"])
button(cb,"LbEx",72, SCRIPT_MAP["LbEx"])
button(cb,"Spin",104, SCRIPT_MAP["Spin"])

header(cb,"Movement",144)
button(cb,"CFrame",176, SCRIPT_MAP["CFrame"])
button(cb,"Fly",208, SCRIPT_MAP["Fly"])
button(cb,"External Shift",240, SCRIPT_MAP["External Shift"])

header(cb,"Animations",280)
button(cb,"Gaze",312, SCRIPT_MAP["Gaze"])
button(cb,"AFEM",344, SCRIPT_MAP["AFEM"])

header(cb,"Exploits",384)
button(cb,"Example Exploit",416, SCRIPT_MAP["Example Exploit"])

header(cb,"Utility",456)
button(cb,"Infinity Yield",488, "InfinityYield")
button(cb,"System Broken",520, SCRIPT_MAP["System Broken"])

local aspectBox = textbox(cb,"AspectR (0.01-1.00)",552)
aspectBox.FocusLost:Connect(function()
    local value = tonumber(aspectBox.Text)
    if value and value >= 0.01 and value <= 1.00 then
        showNotification("Setting aspect ratio...", "loading")
        pcall(function()
            getgenv().Resolution = {
                [".gg/scripters"] = value
            }
            local Camera = workspace.CurrentCamera
            if getgenv().gg_scripters == nil then
                game:GetService("RunService").RenderStepped:Connect(
                    function()
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1)
                    end
                )
            end
            getgenv().gg_scripters = "Aori0001"
            showNotification("Aspect ratio applied: " .. value, "success")
        end)
    else
        showNotification("Value must be 0.01-1.00", "error")
    end
end)

local open = true
local toggleCooldown = false
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Config.OpenClose and not toggleCooldown then
        toggleCooldown = true
        open = not open
        screenGui.Enabled = true

        TweenService:Create(overlay,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{
            BackgroundTransparency = open and 0.5 or 1
        }):Play()

        TweenService:Create(blur,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{
            Size = open and 50 or 0
        }):Play()

        if not open then
            task.delay(0.3,function()
                screenGui.Enabled = false
                toggleCooldown = false
            end)
        else
            task.delay(0.4,function()
                toggleCooldown = false
            end)
        end
    end
end)
local gradient = Instance.new("UIGradient",logo)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(143,  255,  248)), --  Pink | 39, 104, 217
    ColorSequenceKeypoint.new(1, Color3.fromRGB(61,   117,  114))  --  Pink | 2, 61, 163 
}
task.spawn(function()
    local info = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1) -- -1 значит бесконечно
    local tween = TweenService:Create(gradient, info, { Rotation = 360 })
    tween:Play()
end)
showNotification("RL Legacy loaded", "success")
showNotification("by hux9z", "info")