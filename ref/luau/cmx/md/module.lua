-- [ luau/cmx/md/module.lua ]
local ModuleSystem = {}
local HttpService = game:GetService("HttpService")
local Security      = nil
local Helpers       = nil
local LoadedModules = nil
local DoClearFn     = nil
local GetVersionFn  = nil
local ApplyFn       = nil
local MODULES_PATH  = "iME/CMX/modules/"
local DB_PATH       = "iME/CMX/db/"

function ModuleSystem.Init(cfg)
    Security      = cfg.Security
    Helpers       = cfg.Helpers
    LoadedModules = cfg.LoadedModules
    DoClearFn     = cfg.DoClear
    GetVersionFn  = cfg.GetVersion
    ApplyFn       = cfg.Apply
    MODULES_PATH  = cfg.MODULES_PATH or MODULES_PATH
    DB_PATH       = cfg.DB_PATH      or DB_PATH
end

local function SaveURL(modName, url)
    local path = DB_PATH .. "url.json"
    local db = {}
    if isfile(path) then
        local s, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if s then db = r end
    end
    db[modName:lower()] = url
    writefile(path, HttpService:JSONEncode(db))
end

local function LoadURL(modName)
    local path = DB_PATH .. "url.json"
    if not isfile(path) then return nil end
    local s, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if s and r then return r[modName:lower()] end
    return nil
end

local function SavePrevURL(modName, url)
    local path = DB_PATH .. "prev_url.json"
    local db = {}
    if isfile(path) then
        local s, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if s then db = r end
    end
    db[modName:lower()] = url
    writefile(path, HttpService:JSONEncode(db))
end

local function LoadPrevURL(modName)
    local path = DB_PATH .. "prev_url.json"
    if not isfile(path) then return nil end
    local s, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if s and r then return r[modName:lower()] end
    return nil
end

local function ParseModule(res)
    local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
    if ok and data then return data end

    local fn, err = loadstring("return " .. res)
    if fn then
        local lok, data2 = pcall(fn)
        if lok and data2 then return data2 end
    end

    local fn2, err2 = loadstring(res)
    if fn2 then
        local lok2, data3 = pcall(fn2)
        if lok2 and data3 then return data3 end
    end

    return nil
end

function ModuleSystem.Load(url, isOldVersion)
    local s, res = pcall(game.HttpGet, game, url)
    if not s or not res then
        warn("095 Error || Function 'mload' unavailable now.")
        return false
    end

    local modData = ParseModule(res)
    if not modData then
        warn("095 Error || Function 'mload' unavailable now.")
        return false
    end

    local meta    = modData.metainfo or modData
    local library = modData.library  or {}
    local modName = tostring(meta.NameModule or "Unknown"):lower()

    Security.ValidateModule(meta, modName)

    if not Security.CheckVersion(modName, meta.sversion, GetVersionFn()) then
        return false
    end

    local callS = meta.callsyntax or ""
    if callS ~= "" then
        if not Security.RegisterCallsyntax(modName, callS) then
            return false
        end
    end

    local folderName = meta.folder or meta.Author or modName
    local modFolder  = MODULES_PATH .. folderName .. "/"
    if not isfolder(MODULES_PATH) then makefolder(MODULES_PATH) end
    if not isfolder(modFolder)    then makefolder(modFolder)    end

    local sandbox = Security.CreateSandbox(modName, meta.Author, modFolder)
    if Helpers then
        Helpers.Inject(sandbox, DoClearFn)
    end

    LoadedModules[modName] = {
        meta    = meta,
        library = library,
        sandbox = sandbox,
        url     = url,
    }

    Security.RegisterModule(modName, {
        callsyntax = callS,
        author     = meta.Author,
        folder     = folderName,
    })

    if callS ~= "" and callS ~= "js" then
        local sym    = meta.csymbol or "()"
        local openS  = sym:sub(1, 1)
        local closeS = sym:sub(2, 2)
        getgenv()[callS] = function(name, mode)
            for _, item in pairs(library) do
                if item.Name:lower() == tostring(name):lower() then
                    ApplyFn(item, sandbox)
                    return
                end
            end
        end
    end

    if not isOldVersion then
        local existingURL = LoadURL(modName)
        if existingURL and existingURL ~= url then
            SavePrevURL(modName, existingURL)
        end
        SaveURL(modName, url)
    end

    print("JS³² || Module '" .. (meta.NameModule or modName) .. "' by " .. (meta.Author or "Unknown") .. " loaded || " .. (meta.VersionModule or ""))
    return true
end

function ModuleSystem.Unload(modName)
    local n = tostring(modName):lower()
    local mod = LoadedModules[n]
    if not mod then
        warn("JS³² || Module '" .. modName .. "' not found")
        return false
    end
    local callS = mod.meta.callsyntax or ""
    if callS ~= "" then
        Security.UnregisterCallsyntax(n)
        getgenv()[callS] = nil
    end
    Security.UnregisterModule(n)
    LoadedModules[n] = nil
    print("JS³² || Module '" .. (mod.meta.NameModule or modName) .. "' unloaded")
    return true
end

function ModuleSystem.Update(modName)
    local n   = tostring(modName):lower()
    local url = LoadURL(n)
    if not url then
        warn("JS³² || No saved URL for module '" .. modName .. "'")
        return false
    end
    ModuleSystem.Unload(n)
    return ModuleSystem.Load(url, false)
end

function ModuleSystem.OldLoad(modName)
    local n    = tostring(modName):lower()
    local prev = LoadPrevURL(n)
    if not prev then
        warn("JS³² || No previous version saved for module '" .. modName .. "'")
        return false
    end
    ModuleSystem.Unload(n)
    local ok = ModuleSystem.Load(prev, true)
    if ok then
        print("JS³² || Loaded previous version of '" .. modName .. "'")
    end
    return ok
end

function ModuleSystem.BuildCMDLines(IsVerifiedFn)
    local lines = {}

    if not next(LoadedModules) then return lines end

    table.insert(lines, "    Installed by you")
    table.insert(lines, "")

    for _, mod in pairs(LoadedModules) do
        local meta    = mod.meta
        local library = mod.library or {} 
        local verified = IsVerifiedFn and IsVerifiedFn(meta.Author) or false
        local verMark  = verified and " [✓]" or ""
        local social   = ""
        if meta.socials and #meta.socials > 0 then
            social = " || " .. table.concat(meta.socials, " | ")
        end

        table.insert(lines, " " .. (meta.NameModule or "?") .. " by " .. (meta.Author or "?") .. verMark .. " || " .. (meta.VersionModule or "?") .. social)

        local callS  = meta.callsyntax or "js"
        local sym    = (meta.csymbol and meta.csymbol ~= "") and meta.csymbol or "()"
        local openS  = sym:sub(1, 1)
        local closeS = sym:sub(2, 2)

        local groups  = {}
        local noClass = {}

        for _, item in pairs(mod.library or {}) do
            local cls = item.Class or "-"
            local sub = item.SubClass or ""

            local isSecret = (cls == "secret")
            if not isSecret and meta.SClasses then
                for _, sc in pairs(meta.SClasses) do
                    if cls:lower() == sc:lower() then isSecret = true break end
                end
            end
            if not isSecret and meta.SSubClasses then
                for _, ssc in pairs(meta.SSubClasses) do
                    if sub:lower() == ssc:lower() then isSecret = true break end
                end
            end

            if not isSecret then
                local classAllowed = false
                if meta.Classes then
                    for _, mc in pairs(meta.Classes) do
                        if cls:lower() == mc:lower() then classAllowed = true break end
                    end
                end

                if cls == "-" or cls == "NoClass" or cls == "" then
                    table.insert(noClass, item)
                elseif classAllowed then
                    if not groups[cls] then groups[cls] = {} end
                    if not groups[cls][sub] then groups[cls][sub] = {} end
                    table.insert(groups[cls][sub], item)
                end
            end
        end

        for cls, subs in pairs(groups) do
            table.insert(lines, "  [ " .. cls .. " ]")
            if subs[""] then
                for _, item in pairs(subs[""]) do
                    table.insert(lines, "    " .. item.Name .. string.rep(" ", math.max(1, 22 - #item.Name)) .. "|   " .. callS .. openS .. '"' .. item.Name .. '"' .. closeS)
                end
            end
            for sub, items in pairs(subs) do
                if sub ~= "" then
                    table.insert(lines, "    [ " .. sub .. " ]")
                    for _, item in pairs(items) do
                        table.insert(lines, "      " .. item.Name .. string.rep(" ", math.max(1, 20 - #item.Name)) .. "|   " .. callS .. openS .. '"' .. item.Name .. '"' .. closeS)
                    end
                end
            end
            table.insert(lines, "")
        end

        if #noClass > 0 then
            for _, item in pairs(noClass) do
                table.insert(lines, "  " .. item.Name .. string.rep(" ", math.max(1, 22 - #item.Name)) .. "|   " .. callS .. openS .. '"' .. item.Name .. '"' .. closeS)
            end
            table.insert(lines, "")
        end
    end

    return lines
end

return ModuleSystem