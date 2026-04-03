-- Prototype Phone | Loader
-- xELO LLC / SyntoriMS

local PP_VERSION = "0.1.0"
local PP_BASE_URL = "https://aqusu.pages.dev/" -- замени на свой CF path

local files = {
    UI         = PP_BASE_URL   .. "PP/UI",
    StaticPhone= PP_BASE_URL   .. "PP/StaticPhone",
    SS         = PP_BASE_URL   .. "PP/SS",
    SSl        = PP_BASE_URL   .. "PP/SSl",
    Messages   = PP_BASE_URL   .. "PP/apps/Messages",
    Contacts   = PP_BASE_URL   .. "PP/apps/Contacts",
    Store      = PP_BASE_URL   .. "PP/apps/Store",
    Settings   = PP_BASE_URL   .. "PP/apps/Settings",
    Notification = PP_BASE_URL .. "PP/apps/Notification",
}

-- Anti-reduplicate
if getgenv().PP_LOADEDIdevELECTROX0 then
    warn("[PP] Already loaded, skipping.")
    return
end
getgenv().PP_LOADEDIdevELECTROX0 = true

-- Папки
local ROOT = "xELO LLC/PP/"
local FOLDERS = {
    ROOT,
    ROOT .. "History/",
    ROOT .. "History/Messages/",
    ROOT .. "Contacts/",
    ROOT .. "Contacts/All_Contacts/",
}

for _, path in ipairs(FOLDERS) do
    if not isfolder(path) then
        makefolder(path)
    end
end

-- Loader util
local function load(name, url)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[PP] Failed to load " .. name .. ": " .. tostring(result))
        return nil
    end
    return result
end

-- Load order
print("[PP] Loading Prototype Phone v" .. PP_VERSION)

local SS           = load("SS",           files.SS)
local StaticPhone  = load("StaticPhone",  files.StaticPhone)
local Notification = load("Notification", files.Notification)
local UI           = load("UI",           files.UI)

-- Apps грузит сам UI, но если нужно отдельно:
getgenv().PP = {
    Version      = PP_VERSION,
    SS           = SS,
    StaticPhone  = StaticPhone,
    Notification = Notification,
    UI           = UI,
    Root         = ROOT,
}

print("[PP] Loaded successfully")