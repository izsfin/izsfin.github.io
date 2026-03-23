local RELOADASS_URL = "https://nekoq.vercel.app/assets.lua"

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
    ["hux7z/assets/icon/SWANMO_B.png"] = "swanmo_b",
	["hux7z/assets/bg/bg.png"] = "bgswnmo",
    ["hux7z/assets/icon/swanmo_lb.png"] = "swanmo_lb",
}

local assetURL = {
    ["swanmo_b"] = "https://nekoq-cdn.vercel.app/assets/icon/swanmo/SWANMO_B",
    ["bgswnmo"] = "https://nekoq-cdn.vercel.app/assets/icon/swanmo/bg/bg",
    ["swanmo_lb"] = "https://nekoq-cdn.vercel.app/assets/icon/swanmo/swanmo_lb",
}
local function downloadAsset(path, name)
    local url = assetURL[name]
    if not url then
        warn("assets || No URL for asset: " .. name)
        return false
    end
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
                print("assets || Downloading asset: " .. name)
                downloadAsset(path, name)
            end
            if isfile(path) then
                local ok, id = pcall(getcustomasset, path)
                if ok then
                    assets[name] = id
                else
                    warn("assets || getcustomasset failed: " .. path)
                    assets[name] = ""
                end
            else
                warn("assets || Asset not found: " .. path)
                assets[name] = ""
            end
        end
    end
    print("assets || loaded!")
end

function assets.restart()
    loadstring(game:HttpGet(RELOADASS_URL))()
end

function assets.unload()
    for k in pairs(getgenv().assets) do
        getgenv().assets[k] = nil
    end
    getgenv().assets = nil
    print("assets || unloaded!")
end

loadAssets(nil)