local RELOADASS_URL = "https://ethereos.vercel.app/assets"

getgenv().assets = {}

local function ensurePath(path)
    local current = ""
    for folder in path:gmatch("([^/]+)/") do
        current = current == "" and folder or current .. "/" .. folder
        if not isfolder(current) then makefolder(current) end
    end
end

local assetMap = {
    ["nilletMS/assets/icons/NixuC.png"]    = "NixuC",
    ["nilletMS/assets/icons/SomeIcon.png"] = "SomeIcon",
    ["nilletMS/assets/icons/Logo.png"]     = "Logo",
}

local function loadAssets()
    for path, name in pairs(assetMap) do
        ensurePath(path)
        if isfile(path) then
            local ok, id = pcall(getcustomasset, path)
            if ok then
                assets[name] = id
            else
                warn("🔴 getcustomasset упал: " .. path)
                assets[name] = ""
            end
        else
            warn("🔴 Не найден: " .. path)
            assets[name] = ""
        end
    end
    print("✅ assets загружен!")
end

-- Перезапуск с сайта
function assets.restart()
    assets.unload()
    loadstring(game:HttpGet(RELOADASS_URL))()
end

function assets.unload()
    for k in pairs(assets) do
        assets[k] = nil
    end
    getgenv().assets = nil
    print("✅ assets выгружен!")
end

loadAssets()

