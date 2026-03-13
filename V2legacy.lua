-- ================= SCRIPT MAPPING =================
local SCRIPT_MAP = {
    ["VD | TexxRBLX"] = "VDTexRBLX",
    ["AntiSPEmot"]    = "DisableStopEmote",
    ["VD MW"]         = "MoonWalk",
    ["WhakizashiX"]   = "WhakazhiHubX",
    ["Dara Hub"]      = "DaraHub",
    ["Kron Hub"]      = "KronHub",
    ["Vertex"]        = "VertexMM2",
    ["XHub"]          = "XHubMM2",
    ["ODH"]           = "ODHMM2",
    ["FPS x Ping"]    = "FPSxPing",
    ["R6 → R15"]      = "R6toR15",
    ["ESP"]           = "ESPwa",
    ["LbEx"]          = "LimbExtender_rewrite",
    ["Spin"]          = "Spin",
    ["CFrame"]        = "Cframe",
    ["Fly"]           = "Fly",
    ["External Shift"]= "External_Shift",
    ["Gaze"]          = "Gaze",
    ["AFEM"]          = "afem",
    ["Example Exploit"]= "Exploit",
    ["System Broken"] = "SysBroken",
}

-- ================= ACCENT COLOR =================
local ACCENT      = Color3.fromRGB(99, 145, 224)   
local ACCENT_DIM  = Color3.fromRGB(60, 95, 160)    
local BG_DARK     = Color3.fromRGB(15, 15, 15)
local BG_PANEL    = Color3.fromRGB(20, 20, 20)
local BG_BTN      = Color3.fromRGB(25, 25, 25)
local TEXT_MAIN   = Color3.fromRGB(220, 220, 230)
local TEXT_DIM    = Color3.fromRGB(130, 130, 145)

-- ================= LOADING =================
local notifyQueue = {}
local function showNotification(text, status)
    table.insert(notifyQueue, {text = text, status = status or "info"})
end
showNotification("Loading nixu! Legacy...", "loading")

getgenv().Run    = getgenv().Run    or {}
getgenv().Config = getgenv().Config or {}
for k, v in pairs(SCRIPT_MAP) do
    getgenv().Config[v] = true
end

pcall(function()
    loadstring(game:HttpGet("https://ethereos-api.vercel.app/storage"))()
    showNotification("Modules loaded", "success")
end)

-- ================= SERVICES =================
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local Lighting        = game:GetService("Lighting")
local plr             = Players.LocalPlayer
local gui             = game:GetService("CoreGui")

-- ================= GUI ROOT =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name             = "nixumenu"
screenGui.IgnoreGuiInset   = true
screenGui.ResetOnSpawn     = false
screenGui.DisplayOrder     = 1000000000
screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
screenGui.Enabled          = false
screenGui.Parent           = gui

local overlay = Instance.new("Frame")
overlay.Size                  = UDim2.new(1,0,1,0)
overlay.BackgroundColor3      = Color3.fromRGB(0,0,0)
overlay.BackgroundTransparency = 0
overlay.ZIndex                = 1
overlay.Parent                = screenGui

--[[ ================= BLUR =================
local blur = Instance.new("BlurEffect")
blur.Size   = 0
blur.Parent = Lighting
]]
-- ================= NOTIFICATIONS =================
local notifContainer = Instance.new("Frame")
notifContainer.Size                = UDim2.new(0,320,0,500)
notifContainer.Position            = UDim2.new(1,-330,1,-510)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex              = 999999
notifContainer.Parent              = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding             = UDim.new(0,8)
notifLayout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
notifLayout.SortOrder           = Enum.SortOrder.LayoutOrder
notifLayout.Parent              = notifContainer

local function createNotification(text, status)
    local colors = {
        loading = ACCENT,
        success = Color3.fromRGB(80, 180, 120),
        error   = Color3.fromRGB(200, 70, 70),
        info    = ACCENT,
    }
    local notif = Instance.new("Frame")
    notif.Size                    = UDim2.new(1,0,0,60)
    notif.BackgroundColor3        = BG_PANEL
    notif.BackgroundTransparency  = 0.1
    notif.BorderSizePixel         = 0
    notif.Position                = UDim2.new(0,330,0,0)
    notif.Parent                  = notifContainer
    Instance.new("UICorner",notif).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke",notif)
    stroke.Color       = colors[status] or colors.info
    stroke.Thickness   = 2
    stroke.Transparency= 0.3

    local icon = Instance.new("TextLabel")
    icon.Size                 = UDim2.new(0,40,1,0)
    icon.BackgroundTransparency = 1
    icon.Font                 = Enum.Font.GothamBold
    icon.Text                 = status == "success" and "✓" or status == "error" and "✗" or "⟳"
    icon.TextSize             = 22
    icon.TextColor3           = colors[status] or colors.info
    icon.Parent               = notif

    local label = Instance.new("TextLabel")
    label.Size                = UDim2.new(1,-50,1,0)
    label.Position            = UDim2.new(0,45,0,0)
    label.BackgroundTransparency = 1
    label.Font                = Enum.Font.Gotham
    label.Text                = text
    label.TextSize            = 12
    label.TextWrapped         = true
    label.TextXAlignment      = Enum.TextXAlignment.Left
    label.TextColor3          = TEXT_MAIN
    label.Parent              = notif

    TweenService:Create(notif, TweenInfo.new(0.3,Enum.EasingStyle.Back), {Position = UDim2.new(0,0,0,0)}):Play()
    task.delay(3, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0,330,0,0), BackgroundTransparency=1}):Play()
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency=1}):Play()
        TweenService:Create(icon,  TweenInfo.new(0.3), {TextTransparency=1}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.3), {Transparency=1}):Play()
        task.wait(0.3); notif:Destroy()
    end)
end

task.spawn(function()
    while true do
        if #notifyQueue > 0 then
            local n = table.remove(notifyQueue,1)
            createNotification(n.text, n.status)
            task.wait(0.2)
        end
        task.wait(0.1)
    end
end)

-- ================= MAIN FRAME =================
local main = Instance.new("Frame")
main.Size                 = UDim2.new(0,1220,0,580)
main.Position             = UDim2.new(0.5,-610,0.5,-290)
main.BackgroundTransparency = 1
main.ZIndex               = 3
main.Parent               = screenGui

-- ================= HELPERS =================
local function makeCorner(p, r)
    local c = Instance.new("UICorner",p); c.CornerRadius = UDim.new(0,r or 8); return c
end
local function makeStroke(p, color, t)
    local s = Instance.new("UIStroke",p)
    s.Color = color or ACCENT; s.Thickness = 1; s.Transparency = t or 0.7; return s
end


local function createSection(name, width, x)
    local f = Instance.new("Frame")
    f.Name                    = name
    f.Size                    = UDim2.new(0,width,0,560)
    f.Position                = UDim2.new(0,x,0,0)
    f.BackgroundColor3        = BG_PANEL
    f.BackgroundTransparency  = 0.2
    f.BorderSizePixel         = 0
    f.ClipsDescendants        = false
    f.Parent                  = main
    makeCorner(f,14)
    makeStroke(f, ACCENT_DIM, 0.6)

    
    local bgImg = Instance.new("ImageLabel")
    bgImg.Name               = "_BgImage"
    bgImg.Size               = UDim2.new(1,0,1,0)
    bgImg.BackgroundTransparency = 1
    bgImg.ImageTransparency  = 0.4
    bgImg.ScaleType          = Enum.ScaleType.Crop
    bgImg.ZIndex             = 1
    bgImg.Image              = ""
    bgImg.Parent             = f
    makeCorner(bgImg,14)

    return f
end

local function header(p, text, y)
    local h = Instance.new("TextLabel")
    h.Size                 = UDim2.new(1,-16,0,24)
    h.Position             = UDim2.new(0,8,0,y)
    h.BackgroundTransparency = 1
    h.Font                 = Enum.Font.GothamBold
    h.Text                 = text
    h.TextSize             = 15
    h.TextXAlignment       = Enum.TextXAlignment.Left
    h.TextColor3           = ACCENT
    h.ZIndex               = 2
    h.Parent               = p

    local line = Instance.new("Frame")
    line.Size              = UDim2.new(0,50,0,2)
    line.Position          = UDim2.new(0,8,0,y+26)
    line.BackgroundColor3  = ACCENT_DIM
    line.BorderSizePixel   = 0
    line.ZIndex            = 2
    line.Parent            = p
end

local function button(p, text, y, scriptName)
    local b = Instance.new("TextButton")
    b.Name                 = text
    b.Size                 = UDim2.new(1,-16,0,28)
    b.Position             = UDim2.new(0,8,0,y)
    b.BackgroundColor3     = BG_BTN
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel      = 0
    b.Font                 = Enum.Font.Gotham
    b.Text                 = "  "..text
    b.TextSize             = 13
    b.TextWrapped          = true
    b.TextXAlignment       = Enum.TextXAlignment.Left
    b.TextColor3           = TEXT_MAIN
    b.ZIndex               = 2
    b.Parent               = p
    makeCorner(b,8)
    local stroke = makeStroke(b, ACCENT, 0.7)

    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(35,35,40),BackgroundTransparency=0.1}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.15),{Transparency=0.2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BG_BTN,BackgroundTransparency=0.3}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.15),{Transparency=0.7}):Play()
    end)
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=ACCENT_DIM,BackgroundTransparency=0}):Play()
        task.wait(0.12)
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=BG_BTN,BackgroundTransparency=0.3}):Play()

        if scriptName == "InfinityYield" then
            showNotification("Loading Infinity Yield...", "loading")
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
                showNotification("Infinity Yield loaded", "success")
            end)
        elseif getgenv().Run and scriptName and getgenv().Run[scriptName] then
            showNotification("Executing "..text.."...", "loading")
            local ok,err = pcall(getgenv().Run[scriptName])
            if ok then showNotification(text.." executed","success")
            else showNotification("Error: "..tostring(err),"error") end
        else
            showNotification("Not found: "..(scriptName or "?"),"error")
        end
    end)
    return b
end

local function textbox(p, placeholder, y)
    local t = Instance.new("TextBox")
    t.Size                 = UDim2.new(1,-16,0,28)
    t.Position             = UDim2.new(0,8,0,y)
    t.BackgroundColor3     = BG_BTN
    t.BackgroundTransparency = 0.3
    t.BorderSizePixel      = 0
    t.Font                 = Enum.Font.Gotham
    t.PlaceholderText      = placeholder
    t.PlaceholderColor3    = TEXT_DIM
    t.Text                 = ""
    t.TextSize             = 12
    t.TextXAlignment       = Enum.TextXAlignment.Left
    t.TextColor3           = TEXT_MAIN
    t.ClearTextOnFocus     = false
    t.ZIndex               = 2
    t.Parent               = p
    makeCorner(t,8)
    makeStroke(t, ACCENT, 0.75)
    local pad = Instance.new("UIPadding",t); pad.PaddingLeft = UDim.new(0,10)
    return t
end


local function addBgInput(section, yPos)
    local tb = textbox(section, "Panel BG (Asset ID)", yPos)
    tb.FocusLost:Connect(function()
        local id = tb.Text:match("%d+")
        local bgImg = section:FindFirstChild("_BgImage")
        if bgImg then
            if id then
                bgImg.Image = "rbxassetid://"..id
                showNotification("Panel BG applied","success")
            else
                bgImg.Image = ""
            end
        end
    end)
    return tb
end


local function smallBtn(p, text, y, func)
    local b = Instance.new("TextButton")
    b.Size                 = UDim2.new(1,-16,0,26)
    b.Position             = UDim2.new(0,8,0,y)
    b.BackgroundColor3     = BG_BTN
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel      = 0
    b.Font                 = Enum.Font.GothamBold
    b.Text                 = text
    b.TextSize             = 11
    b.TextColor3           = ACCENT
    b.ZIndex               = 2
    b.Parent               = p
    makeCorner(b,7)
    makeStroke(b, ACCENT, 0.6)
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=0,BackgroundColor3=ACCENT_DIM}):Play()
        TweenService:Create(b,TweenInfo.new(0.15),{TextColor3=Color3.new(1,1,1)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=0.2,BackgroundColor3=BG_BTN}):Play()
        TweenService:Create(b,TweenInfo.new(0.15),{TextColor3=ACCENT}):Play()
    end)
    b.MouseButton1Click:Connect(function()
        pcall(func)
    end)
    return b
end


local nl = createSection("NL", 200, 0)
nl.BackgroundColor3       = BG_PANEL
nl.BackgroundTransparency = 0.2


local logo = Instance.new("TextLabel")
logo.Size                 = UDim2.new(1,-16,0,40)
logo.Position             = UDim2.new(0,8,0,14)
logo.BackgroundTransparency = 1
logo.Font                 = Enum.Font.GothamBold
logo.Text                 = "Nixu Legacy"
logo.TextSize             = 22
logo.TextColor3           = ACCENT
logo.ZIndex               = 2
logo.Parent               = nl

local grad = Instance.new("UIGradient",logo)
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, ACCENT),
    ColorSequenceKeypoint.new(1, ACCENT_DIM),
}

local subLogo = Instance.new("TextLabel")
subLogo.Size               = UDim2.new(1,-16,0,16)
subLogo.Position           = UDim2.new(0,8,0,52)
subLogo.BackgroundTransparency = 1
subLogo.Font               = Enum.Font.Gotham
subLogo.Text               = "ethereos.vercel.app"
subLogo.TextSize           = 10
subLogo.TextColor3         = TEXT_DIM
subLogo.ZIndex             = 2
subLogo.Parent             = nl


local div1 = Instance.new("Frame")
div1.Size                  = UDim2.new(1,-16,0,1)
div1.Position              = UDim2.new(0,8,0,76)
div1.BackgroundColor3      = ACCENT_DIM
div1.BackgroundTransparency = 0.7
div1.BorderSizePixel       = 0
div1.ZIndex                = 2
div1.Parent                = nl

-- Contacts header
header(nl,"Contacts",86)

smallBtn(nl,"Discord →",118, function()
    setclipboard("https://discord.gg/TRPZg4Xfkq")
    showNotification("Discord link copied!","success")
end)
smallBtn(nl,"Website →",150, function()
    setclipboard("https://ethereos.vercel.app")
    showNotification("Website link copied!","success")
end)


local div2 = Instance.new("Frame")
div2.Size                  = UDim2.new(1,-16,0,1)
div2.Position              = UDim2.new(0,8,0,188)
div2.BackgroundColor3      = ACCENT_DIM
div2.BackgroundTransparency = 0.7
div2.BorderSizePixel       = 0
div2.ZIndex                = 2
div2.Parent                = nl

-- Scripts header
header(nl,"Scripts",198)

smallBtn(nl,"Load Spectral",230, function()
    showNotification("Loading Spectral...","loading")
    local ok,err = pcall(function() getgenv().Run.spectral() end)
    if ok then showNotification("Spectral loaded","success")
    else showNotification("Error: "..tostring(err),"error") end
end)
smallBtn(nl,"Load DLC",262, function()
    showNotification("Loading DLC...","loading")
    local ok,err = pcall(function() getgenv().Run.NixuDLC() end)
    if ok then showNotification("DLC loaded","success")
    else showNotification("Error: "..tostring(err),"error") end
end)
smallBtn(nl,"Load Nixu",294, function()
    showNotification("Loading Nixu...","loading")
    local ok,err = pcall(function() getgenv().Run.Nixu() end)
    if ok then showNotification("Nixu loaded","success")
    else showNotification("Error: "..tostring(err),"error") end
end)


local div3 = Instance.new("Frame")
div3.Size                  = UDim2.new(1,-16,0,1)
div3.Position              = UDim2.new(0,8,0,334)
div3.BackgroundColor3      = ACCENT_DIM
div3.BackgroundTransparency = 0.7
div3.BorderSizePixel       = 0
div3.ZIndex                = 2
div3.Parent                = nl




local version = Instance.new("TextLabel")
version.Size               = UDim2.new(1,-16,0,16)
version.Position           = UDim2.new(0,8,1,-24)
version.BackgroundTransparency = 1
version.Font               = Enum.Font.Gotham
version.Text               = "v2.1.56 | Release Build"
version.TextSize           = 10
version.TextXAlignment     = Enum.TextXAlignment.Left
version.TextColor3         = TEXT_DIM
version.ZIndex             = 2
version.Parent             = nl

-- ================= VIOLENCE DISTRICT / EVADE / LT2 / MM2 =================
local vd = createSection("ViolenceDistrict", 220, 210)
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

-- ================= CHANGELOGS =================
local cl = createSection("ChangeLogs", 220, 440)
header(cl,"ChangeLogs",8)
local log = Instance.new("TextLabel")
log.Size               = UDim2.new(1,-16,0,90)
log.Position           = UDim2.new(0,8,0,40)
log.BackgroundTransparency = 1
log.Font               = Enum.Font.Gotham
log.Text               = "Update 2.1.56\n• Custom decal support\n• SkyBox & OutFit system\n• AspectRatio control\n• Scrollable panels"
log.TextSize           = 12
log.TextXAlignment     = Enum.TextXAlignment.Left
log.TextYAlignment     = Enum.TextYAlignment.Top
log.TextColor3         = TEXT_MAIN
log.TextWrapped        = true
log.ZIndex             = 2
log.Parent             = cl
header(cl,"About",140)
local about = Instance.new("TextLabel")
about.Size             = UDim2.new(1,-16,0,50)
about.Position         = UDim2.new(0,8,0,172)
about.BackgroundTransparency = 1
about.Font             = Enum.Font.Gotham
about.Text             = "Multi-functional menu\nfor Roblox with\nmodular architecture"
about.TextSize         = 11
about.TextXAlignment   = Enum.TextXAlignment.Left
about.TextYAlignment   = Enum.TextYAlignment.Top
about.TextColor3       = TEXT_DIM
about.ZIndex           = 2
about.Parent           = cl


local ov = createSection("Overlay", 220, 670)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                  = UDim2.new(1,0,1,0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel       = 0
scrollFrame.ScrollBarThickness    = 3
scrollFrame.ScrollBarImageColor3  = ACCENT
scrollFrame.ScrollBarImageTransparency = 0.5
scrollFrame.CanvasSize            = UDim2.new(0,0,1.4,0)
scrollFrame.Parent                = ov

header(scrollFrame,"Overlay",8)
button(scrollFrame,"FPS x Ping",40, SCRIPT_MAP["FPS x Ping"])
header(scrollFrame,"Client Changer",80)
button(scrollFrame,"R6 → R15",112, SCRIPT_MAP["R6 → R15"])
header(scrollFrame,"OutFit",152)
local shirtInput = textbox(scrollFrame,"Shirt ID",184)
local pantsInput = textbox(scrollFrame,"Pants ID",216)
shirtInput.FocusLost:Connect(function()
    local id = tonumber(shirtInput.Text)
    if id then
        pcall(function()
            local char = plr.Character
            if char then
                local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt",char)
                shirt.ShirtTemplate = "rbxassetid://"..id
                showNotification("Shirt applied","success")
            end
        end)
    end
end)
pantsInput.FocusLost:Connect(function()
    local id = tonumber(pantsInput.Text)
    if id then
        pcall(function()
            local char = plr.Character
            if char then
                local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants",char)
                pants.PantsTemplate = "rbxassetid://"..id
                showNotification("Pants applied","success")
            end
        end)
    end
end)

-- ================= COMBAT / MOVEMENT / EXPLOITS =================
local cb = createSection("Combat", 220, 900)
local cbScroll = Instance.new("ScrollingFrame")
cbScroll.Size = UDim2.new(1,0,1,0)
cbScroll.BackgroundTransparency = 1
cbScroll.BorderSizePixel = 0
cbScroll.ScrollBarThickness = 3
cbScroll.ScrollBarImageColor3 = ACCENT
cbScroll.ScrollBarImageTransparency = 0.5
cbScroll.CanvasSize = UDim2.new(0,0,0,500)
cbScroll.Parent = cb
header(cbScroll,"Combat",8)
button(cbScroll,"ESP",40, SCRIPT_MAP["ESP"])
button(cbScroll,"LbEx",72, SCRIPT_MAP["LbEx"])
button(cbScroll,"Spin",104, SCRIPT_MAP["Spin"])
header(cbScroll,"Movement",144)
button(cbScroll,"CFrame",176, SCRIPT_MAP["CFrame"])
button(cbScroll,"Fly",208, SCRIPT_MAP["Fly"])
button(cbScroll,"External Shift",240, SCRIPT_MAP["External Shift"])
header(cbScroll,"Animations",280)
button(cbScroll,"Gaze",312, SCRIPT_MAP["Gaze"])
button(cbScroll,"AFEM",344, SCRIPT_MAP["AFEM"])
header(cbScroll,"Utility",456)
button(cbScroll,"Infinity Yield",488,"InfinityYield")
button(cbScroll,"System Broken",520, SCRIPT_MAP["System Broken"])
local aspectBox = textbox(cbScroll,"AspectR (0.01-1.00)",420)
aspectBox.FocusLost:Connect(function()
    local value = tonumber(aspectBox.Text)
    if value and value >= 0.01 and value <= 1.00 then
        pcall(function()
            getgenv().Resolution = { [".gg/scripters"] = value }
            local Camera = workspace.CurrentCamera
            if not getgenv().gg_scripters then
                game:GetService("RunService").RenderStepped:Connect(function()
                    Camera.CFrame = Camera.CFrame * CFrame.new(0,0,0,1,0,0,0,getgenv().Resolution[".gg/scripters"],0,0,0,1)
                end)
            end
            getgenv().gg_scripters = "Aori0001"
            showNotification("AspectRatio: "..value,"success")
        end)
    else
        showNotification("Value must be 0.01–1.00","error")
    end
end)



local allSections = {nl, vd, cl, ov, cb}


local bgInputLabel = Instance.new("TextLabel")
bgInputLabel.Size               = UDim2.new(1,-16,0,16)
bgInputLabel.Position           = UDim2.new(0,8,0,420)
bgInputLabel.BackgroundTransparency = 1
bgInputLabel.Font               = Enum.Font.GothamBold
bgInputLabel.Text               = "ALL PANELS BG"
bgInputLabel.TextSize           = 10
bgInputLabel.TextColor3         = ACCENT_DIM
bgInputLabel.TextXAlignment     = Enum.TextXAlignment.Left
bgInputLabel.ZIndex             = 2
bgInputLabel.Parent             = nl

local bgInputBox = textbox(nl, "Asset ID (all panels)", 440)

bgInputBox.FocusLost:Connect(function()
    local id = bgInputBox.Text:match("%d+")
    for _, section in ipairs(allSections) do
        local bgImg = section:FindFirstChild("_BgImage")
        if not bgImg then
            
            for _, child in ipairs(section:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    bgImg = child:FindFirstChild("_BgImage")
                    if not bgImg then
                        bgImg = Instance.new("ImageLabel")
                        bgImg.Name               = "_BgImage"
                        bgImg.Size               = UDim2.new(1,0,1,0)
                        bgImg.BackgroundTransparency = 1
                        bgImg.ImageTransparency  = 0.35
                        bgImg.ScaleType          = Enum.ScaleType.Crop
                        bgImg.ZIndex             = 1
                        bgImg.Image              = ""
                        bgImg.Parent             = section
                        Instance.new("UICorner", bgImg).CornerRadius = UDim.new(0,14)
                    end
                end
            end
        end
        if not bgImg then
            bgImg = section:FindFirstChild("_BgImage")
        end
        if bgImg then
            if id then
                bgImg.Image = "rbxassetid://" .. id
            else
                bgImg.Image = ""
            end
        end
    end
    if id then
        showNotification("All panels BG applied", "success")
    else
        showNotification("BG cleared", "info")
    end
end)

-- ================= TOGGLE =================
local open = true
local toggleCooldown = false

UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.BackSlash and not toggleCooldown then
        toggleCooldown = true
        open = not open
        screenGui.Enabled = true
        TweenService:Create(overlay,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{
            BackgroundTransparency = open and 0.5 or 1
        }):Play()
--[[    TweenService:Create(blur,TweenInfo.new(0.3),{
            Size = open and 8 or 0
        }):Play() ]]
        if not open then
            task.delay(0.3, function()
                screenGui.Enabled = false
                toggleCooldown = false
            end)
        else
            task.delay(0.4, function() toggleCooldown = false end)
        end
    end
end)

showNotification("Nixu! Legacy v2.1.56 loaded","success")
showNotification("by xilmess","info")