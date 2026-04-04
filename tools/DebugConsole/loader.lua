-- // DebugConsole Loader
-- // by abuse.electro

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UID  = tostring(LocalPlayer.UserId)
local sUID = ""
local BUID = ""

local Icons = {
    DebugConsole = "Base64",
    Author       = "Base64",
    WaterMark    = "Base64"
}

local Colors = {
    print = "255, 255, 255",
    warn  = "255, 200, 0",
    error = "255, 50, 50",
    urlda = "255, 100, 100"
}

-- // Грузим UI лоадера первым
local Loader = loadstring(game:HttpGet("https://aqusu.pages.dev/~/tools/DebugConsole/LoaderUI"))()

-- // [1] Table
Loader.setStatus("Loading Executor...")
Loader.setStep(1, "loading")
local ok, Table = pcall(function()
    return loadstring(game:HttpGet("https://aqusu.pages.dev/~/tools/DebugConsole/table"))(UID, sUID, nil, BUID)
end)

if not ok or not Table then
    Loader.setStep(1, false)
    Loader.setStatus("Failed to load Table.")
    error("[DC] Failed to load Table: " .. tostring(Table))
end

Loader.setStep(1, true)

local function checkBan()
    if Table.BannedUID then
        for _, id in ipairs(Table.BannedUID) do
            if tostring(id) == UID then
                Loader.setStatus("You are banned.")
                LocalPlayer:Kick("[DebugConsole] You are banned.")
                return true
            end
        end
    end
    return false
end

if checkBan() then return end

local AccessType = "Default"

if Table.SpecialUID then
    for _, id in ipairs(Table.SpecialUID) do
        if tostring(id) == UID then AccessType = "Special" break end
    end
end

if AccessType == "Default" and Table.AllowedUID then
    for _, id in ipairs(Table.AllowedUID) do
        if tostring(id) == UID then AccessType = "Allowed" break end
    end
end

local DCUrl = ""
if AccessType == "Special" or AccessType == "Allowed" then
    local meta = Table.Meta or {}
    DCUrl = meta.verAUID or "https://aqusu.pages.dev/~/tools/DebugConsole/Beta/src"
else
    DCUrl = "https://aqusu.pages.dev/~/tools/DebugConsole/Stable/src"
end

-- // [2] Console
Loader.setStatus("Loading Console...")
Loader.setStep(2, "loading")
task.wait(0.1) -- минимальная пауза чтоб UI обновился
Loader.setStep(2, true)

-- // [3] AntiDC
Loader.setStatus("Loading AntiDC...")
Loader.setStep(3, "loading")
local AntiDC_Milf = loadstring(game:HttpGet("https://aqusu.pages.dev/~/tools/DebugConsole/Anti/MD"))()
local sv = AntiDC_Milf and AntiDC_Milf.sv or "v1"
getgenv()["antiDC" .. sv .. "FS"] = AntiDC_Milf
local AntiDC_loader = loadstring(game:HttpGet("https://aqusu.pages.dev/~/tools/DebugConsole/Anti/Loader"))()
Loader.setStep(3, true)

-- // CheckURL
local function checkURL(url)
    if not Table.DisallowedURL then return false, nil end
    for alias, blockedURL in pairs(Table.DisallowedURL) do
        if url:find(blockedURL, 1, true) then
            local msg = "[DC] URL in blacklist"
            if Table.DisallowedURL_ST and Table.DisallowedURL_ST[alias] then
                msg = Table.DisallowedURL_ST[alias]
            end
            return true, msg
        end
    end
    return false, nil
end

getgenv().DC_CheckURL    = checkURL
getgenv().DC_AccessType  = AccessType
getgenv().DC_Table       = Table
getgenv().DC_Colors      = Colors
getgenv().DC_Icons       = Icons

-- // [4] Modules
Loader.setStatus("Loading Modules...")
Loader.setStep(4, "loading")
task.wait(0.1)
Loader.setStep(4, true)

-- // [5] UI / Static
Loader.setStatus("Loading UI...")
Loader.setStep(5, "loading")
local Static = loadstring(game:HttpGet("https://aqusu.pages.dev/~/tools/DebugConsole/Static"))(Icons, Colors)
Loader.setStep(5, true)

-- // Запускаем основной DC
Loader.setStatus("Starting script...")
task.wait(0.3)
Loader.finish()

local DebugConsole_Milf = loadstring(game:HttpGet(DCUrl))()
print("[DC] Loaded | Access: " .. AccessType)