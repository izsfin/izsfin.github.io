-- Prototype Phone | Loader v0.1.0
-- xELO LLC / SyntoriMS

local PP_VERSION = "0.1.0"
local PP_BASE_URL = "https://aqusu.pages.dev/PP/"

-- Anti-reduplicate
if getgenv().PP_LOADEDIdevELECTROX0 then
    warn("[PP] Already loaded, skipping.")
    return
end
getgenv().PP_LOADEDIdevELECTROX0 = true

-- Инициализация глобальной таблицы СРАЗУ
getgenv().PP = {
    Version  = PP_VERSION,
    Root     = "xELO LLC/PP/",
    AppURLs  = {
        Messages = PP_BASE_URL .. "apps/Messages",
        Contacts = PP_BASE_URL .. "apps/Contacts",
        Store    = PP_BASE_URL .. "apps/Store",
        Settings = PP_BASE_URL .. "apps/Settings",
    },
}

-- Папки
local FOLDERS = {
    "xELO LLC/",
    "xELO LLC/PP/",
    "xELO LLC/PP/Profiles/",
    "xELO LLC/PP/History/",
    "xELO LLC/PP/History/Messages/",
    "xELO LLC/PP/Contacts/",
    "xELO LLC/PP/Contacts/All_Contacts/",
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

print("[PP] Loading Prototype Phone v" .. PP_VERSION)

-- Порядок важен: SS и StaticPhone грузятся первыми
-- остальные файлы обращаются к getgenv().PP.SS и .StaticPhone
local SS          = load("SS",          PP_BASE_URL .. "SS")
getgenv().PP.SS   = SS

local SSl         = load("SSl",         PP_BASE_URL .. "SSl")
getgenv().PP.SSl  = SSl

local StaticPhone = load("StaticPhone", PP_BASE_URL .. "StaticPhone")
getgenv().PP.StaticPhone = StaticPhone

local Notification = load("Notification", PP_BASE_URL .. "apps/Notification")
getgenv().PP.Notification = Notification

local UI          = load("UI",          PP_BASE_URL .. "UI")
getgenv().PP.UI   = UI

-- Инициализация
-- Запуск
if SSl then SSl:Init() end

if UI then
    UI:Init()
    -- Сразу показать телефон при первом запуске
    UI:Toggle()
end
print("[PP] Loaded successfully | v" .. PP_VERSION)