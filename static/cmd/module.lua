print("XMS || Start Loading System...")

local function safeLoad(name, url)
    print("XMS || Fetching: " .. name)
    local res = http.request({
        Url = url,
        Headers = { ["User-Agent"] = "hux9z/software" }
    })
    
    if not res.Success or res.Body == "" then
        warn("XMS || Failed to fetch " .. name .. " (Status: " .. tostring(res.StatusCode) .. ")")
        return nil
    end
    
    local fn, err = loadstring(res.Body)
    if not fn then
        warn("XMS || Syntax Error in " .. name .. ": " .. tostring(err))
        return nil
    end
    
    local ok, ret = pcall(fn)
    if not ok then
        warn("XMS || Runtime Error in " .. name .. ": " .. tostring(ret))
        return nil
    end
    
    print("XMS || Successfully loaded: " .. name)
    return ret
end

-- Поэтапная загрузка с паузами, чтобы не вешать поток
task.wait(0.1)
local Security = safeLoad("Security", "https://nekoq.vercel.app/static/cmd/md/security.lua")
task.wait(0.1)
local Helpers = safeLoad("Helpers", "https://nekoq.vercel.app/static/cmd/md/helpers.lua")
task.wait(0.1)
local MS_Raw = safeLoad("ModuleSystem", "https://nekoq.vercel.app/static/cmd/md/module.lua")

if MS_Raw and Security then
    print("XMS || Initializing ModuleSystem...")
    task.wait(0.1)
    
    -- Оборачиваем Init в pcall, чтобы если он упадет, клиент не вылетел
    local ok, err = pcall(function()
        MS_Raw.Init({
            Security = Security,
            Helpers = Helpers,
            LoadedModules = {},
            DoClear = function() end,
            GetVersion = function() return "1.0.0" end,
            Apply = function() end,
            MODULES_PATH = "hux9z/jsx32/modules/",
            DB_PATH = "hux9z/jsx32/db/"
        })
    end)
    
    if not ok then warn("XMS || Init Error: " .. tostring(err)) end
end

print("XMS || System Ready.")
return MS_Raw