-- ================= SCRIPT MAPPING =================
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
    ["FPS x Ping"] = "FPSxPing",
    ["R6 → R15"] = "R6toR15",
    ["ESP"] = "ESPwa",
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

-- ================= LOADING =================
getgenv().Run = getgenv().Run or {}
getgenv().Config = getgenv().Config or {}
for k, v in pairs(SCRIPT_MAP) do
    getgenv().Config[v] = true
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local plr = Players.LocalPlayer

pcall(function()
    loadstring(game:HttpGet("https://wexly-api.vercel.app/storage"))()
end)
local Run = getgenv().Run

-- ================= SUGAR UI =================
local SugarLibrary = loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/Yomkav2/Sugar-UI/refs/heads/main/Source'))()
local Notification = SugarLibrary.Notification()

local function notify(title, desc, icon, duration)
    Notification.new({
        Title = title,
        Description = desc or "",
        Duration = duration or 3,
        Icon = icon or "info"
    })
end

local function execScript(name, scriptName)
    if scriptName == "InfinityYield" then
        notify("Loading...", "Infinity Yield", "loader")
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
            notify("Loaded", "Infinity Yield", "check")
        end)
    elseif Run and scriptName and Run[scriptName] then
        notify("Executing", name, "play")
        local ok, err = pcall(function() Run[scriptName]() end)
        if ok then
            notify("Done", name, "check")
        else
            notify("Error", tostring(err), "x")
        end
    else
        notify("Not found", scriptName or "unknown", "alert-circle")
    end
end

local Window = SugarLibrary.new({
    Title = "Swanmo",
    Description = "ximeax team",
    Keybind = Enum.KeyCode.BackSlash,
    Logo = "http://www.roblox.com/asset/?id=75225673325066",
    ConfigFolder = "SwanmoConfigs"
})

notify("Swanmo", "Loaded successfully", "check", 4)

-- ================= SGAMES TAB =================
local SGamesTab = Window:NewTab({ Title = "SGames", Description = "Game scripts", Icon = "gamepad-2" })

local VDSection = SGamesTab:NewSection({ Title = "Violence District", Icon = "sword", Position = "Left" })
VDSection:NewButton({ Title = "VD | TexxRBLX",  Callback = function() execScript("VD | TexxRBLX",  SCRIPT_MAP["VD | TexxRBLX"])  end })
VDSection:NewButton({ Title = "AntiSPEmot",     Callback = function() execScript("AntiSPEmot",     SCRIPT_MAP["AntiSPEmot"])     end })
VDSection:NewButton({ Title = "VD MW",          Callback = function() execScript("VD MW",          SCRIPT_MAP["VD MW"])          end })

local EvadeSection = SGamesTab:NewSection({ Title = "Evade", Icon = "zap", Position = "Left" })
EvadeSection:NewButton({ Title = "WhakizashiX", Callback = function() execScript("WhakizashiX", SCRIPT_MAP["WhakizashiX"]) end })
EvadeSection:NewButton({ Title = "Dara Hub",    Callback = function() execScript("Dara Hub",    SCRIPT_MAP["Dara Hub"])    end })

local LT2Section = SGamesTab:NewSection({ Title = "Lumber Tycoon 2", Icon = "tree-pine", Position = "Left" })
LT2Section:NewButton({ Title = "Kron Hub", Callback = function() execScript("Kron Hub", SCRIPT_MAP["Kron Hub"]) end })

local MM2Section = SGamesTab:NewSection({ Title = "MM2", Icon = "knife", Position = "Left" })
MM2Section:NewButton({ Title = "Vertex", Callback = function() execScript("Vertex", SCRIPT_MAP["Vertex"]) end })
MM2Section:NewButton({ Title = "XHub",   Callback = function() execScript("XHub",   SCRIPT_MAP["XHub"])   end })
MM2Section:NewButton({ Title = "ODH",    Callback = function() execScript("ODH",    SCRIPT_MAP["ODH"])    end })

-- ================= MAIN TAB =================
local MainTab = Window:NewTab({ Title = "Main", Description = "Overlay & Combat", Icon = "layout-dashboard" })

-- LEFT — Overlay
local OverlaySection = MainTab:NewSection({ Title = "Overlay", Icon = "monitor", Position = "Left" })
OverlaySection:NewButton({ Title = "FPS x Ping", Callback = function() execScript("FPS x Ping", SCRIPT_MAP["FPS x Ping"]) end })
OverlaySection:NewButton({ Title = "R6 → R15",   Callback = function() execScript("R6 → R15",   SCRIPT_MAP["R6 → R15"])   end })

local SkyboxSection = MainTab:NewSection({ Title = "SkyBox", Icon = "cloud", Position = "Left" })
local skyboxBox = SkyboxSection:NewTextbox({
    Title = "SkyBox ID",
    Default = "",
    FileType = "ID",
    Callback = function(id)
        local skyboxId = tonumber(id)
        if skyboxId then
            notify("Applying", "SkyBox...", "cloud")
            pcall(function()
                local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
                local url = "rbxassetid://" .. skyboxId
                sky.SkyboxBk = url sky.SkyboxDn = url sky.SkyboxFt = url
                sky.SkyboxLf = url sky.SkyboxRt = url sky.SkyboxUp = url
                notify("Done", "SkyBox applied", "check")
            end)
        else
            notify("Error", "Invalid SkyBox ID", "x")
        end
    end
})

local OutfitSection = MainTab:NewSection({ Title = "Outfit", Icon = "shirt", Position = "Left" })
OutfitSection:NewTextbox({
    Title = "Shirt ID",
    Default = "",
    FileType = "ID",
    Callback = function(id)
        local shirtId = tonumber(id)
        if shirtId then
            pcall(function()
                local char = plr.Character
                if char then
                    local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
                    shirt.ShirtTemplate = "rbxassetid://" .. shirtId
                    notify("Done", "Shirt applied", "check")
                end
            end)
        else
            notify("Error", "Invalid Shirt ID", "x")
        end
    end
})
OutfitSection:NewTextbox({
    Title = "Pants ID",
    Default = "",
    FileType = "ID",
    Callback = function(id)
        local pantsId = tonumber(id)
        if pantsId then
            pcall(function()
                local char = plr.Character
                if char then
                    local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
                    pants.PantsTemplate = "rbxassetid://" .. pantsId
                    notify("Done", "Pants applied", "check")
                end
            end)
        else
            notify("Error", "Invalid Pants ID", "x")
        end
    end
})

local AspectSection = MainTab:NewSection({ Title = "Aspect Ratio", Icon = "ratio", Position = "Left" })
AspectSection:NewTextbox({
    Title = "Value (0.01 - 1.00)",
    Default = "",
    FileType = "float",
    Callback = function(val)
        local value = tonumber(val)
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
                notify("Done", "Aspect ratio: " .. value, "check")
            end)
        else
            notify("Error", "Value must be 0.01-1.00", "x")
        end
    end
})

-- RIGHT — Combat
local CombatSection = MainTab:NewSection({ Title = "Combat", Icon = "sword", Position = "Right" })
CombatSection:NewButton({ Title = "ESP",  Callback = function() execScript("ESP",  SCRIPT_MAP["ESP"])  end })
CombatSection:NewButton({ Title = "LbEx", Callback = function() execScript("LbEx", SCRIPT_MAP["LbEx"]) end })
CombatSection:NewButton({ Title = "Spin", Callback = function() execScript("Spin", SCRIPT_MAP["Spin"]) end })

local MovementSection = MainTab:NewSection({ Title = "Movement", Icon = "footprints", Position = "Right" })
MovementSection:NewButton({ Title = "CFrame",          Callback = function() execScript("CFrame",          SCRIPT_MAP["CFrame"])          end })
MovementSection:NewButton({ Title = "Fly",             Callback = function() execScript("Fly",             SCRIPT_MAP["Fly"])             end })
MovementSection:NewButton({ Title = "External Shift",  Callback = function() execScript("External Shift",  SCRIPT_MAP["External Shift"])  end })

local AnimSection = MainTab:NewSection({ Title = "Animations", Icon = "person-standing", Position = "Right" })
AnimSection:NewButton({ Title = "Gaze", Callback = function() execScript("Gaze", SCRIPT_MAP["Gaze"]) end })
AnimSection:NewButton({ Title = "AFEM", Callback = function() execScript("AFEM", SCRIPT_MAP["AFEM"]) end })

local UtilSection = MainTab:NewSection({ Title = "Utility", Icon = "wrench", Position = "Right" })
UtilSection:NewButton({ Title = "Example Exploit", Callback = function() execScript("Example Exploit", SCRIPT_MAP["Example Exploit"]) end })
UtilSection:NewButton({ Title = "Infinity Yield",  Callback = function() execScript("Infinity Yield",  "InfinityYield")               end })
UtilSection:NewButton({ Title = "System Broken",   Callback = function() execScript("System Broken",   SCRIPT_MAP["System Broken"])   end })

-- ================= INFO TAB =================
local InfoTab = Window:NewTab({ Title = "Info", Description = "About & Changelogs", Icon = "info" })

local CLSection = InfoTab:NewSection({ Title = "ChangeLogs", Icon = "scroll-text", Position = "Left" })
CLSection:NewLabel("Update 2.2.0 | Swanmo")
CLSection:NewLabel("• Rewritten on SugarUI")
CLSection:NewLabel("• New branding: ximeax team")
CLSection:NewLabel("• SGames / Main / Info tabs")
CLSection:NewLabel("• Overlay & Combat in Main")

local AboutSection = InfoTab:NewSection({ Title = "About", Icon = "circle-help", Position = "Left" })
AboutSection:NewLabel("Multi-functional menu")
AboutSection:NewLabel("for Roblox by ximeax team")
AboutSection:NewButton({
    Title = "Discord",
    Callback = function()
        pcall(setclipboard, "https://discord.gg/TRPZg4Xfkq")
        notify("Copied", "Discord link copied", "check")
    end
})