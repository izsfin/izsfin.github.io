
local RELOADASS_URL = "https://wexly.vercel.app/assets.lua"
local ASSET_BASE_URL = "https://wexly-cdn.vercel.app/assets/"

getgenv().assets = {}
local assets = getgenv().assets

local function ensurePath(path)
    local current = ""
    for folder in path:gmatch("([^/]+)/") do
        current = current == "" and folder or current .. "/" .. folder
        if not isfolder(current) then makefolder(current) end
    end
end

local assetMap = {
    ["nilletMS/assets/icons/NixuC.png"]         = "NixuC",
    ["nilletMS/assets/icons/SomeIcon.png"]       = "SomeIcon",
    ["nilletMS/assets/icons/Logo.png"]           = "Logo",
    ["nilletMS/assets/icons/swanmo/SWANMO_B.png"] = "swanmo_b",
}

local function downloadAsset(path)
    local url = ASSET_BASE_URL .. path
    local ok, data = pcall(game.HttpGet, game, url)
    if ok and data and data:sub(1,1) ~= "<" then
        ensurePath(path)
        writefile(path, data)
        return true
    end
    return false
end

local function loadAssets(filter)
    for path, name in pairs(assetMap) do
        if not filter or filter[name] then
            ensurePath(path)
            if not isfile(path) then
                print("XMS || Downloading asset: " .. name)
                downloadAsset(path)
            end
            if isfile(path) then
                local ok, id = pcall(getcustomasset, path)
                if ok then
                    assets[name] = id
                else
                    warn("XMS || getcustomasset failed: " .. path)
                    assets[name] = ""
                end
            else
                warn("XMS || Asset not found: " .. path)
                assets[name] = ""
            end
        end
    end
    print("XMS || Assets loaded!")
end

function assets.restart()
    loadstring(game:HttpGet(RELOADASS_URL))()
end

function assets.unload()
    for k in pairs(getgenv().assets) do
        getgenv().assets[k] = nil
    end
    getgenv().assets = nil
    print("XMS || Assets unloaded!")
end

return function(...)
    local args = {...}
    if #args > 0 then
        local filter = {}
        for _, name in pairs(args) do filter[name] = true end
        loadAssets(filter)
    else
        loadAssets(nil)
    end
end