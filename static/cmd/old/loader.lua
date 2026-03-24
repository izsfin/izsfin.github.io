-- URL: https://nekoq.vercel.app/static/cmd/loader_logic
local loader = {}

-- Таблица соответствий (Callname -> Path)
local name_map = {
    ["library"] = "static/cmd",
    ["meta"]    = "static/cmd/meta",
    ["main"]    = "static/cmd/logic",
    ["module"]  = "static/cmd/module"
}

function loader.fill(target_table, ua, base)
    local function qload(path)
        local success, res = pcall(function() 
            return game:HttpGet(base .. path, true) 
        end)
        if not success or not res then return nil end
        
        local fn, err = loadstring(res)
        if not fn then return nil end
        return fn()
    end

    -- Заполняем основное
    target_table.library = qload(name_map["library"])
    target_table.meta    = qload(name_map["meta"])

    -- Заполняем логику через callname из таблицы using
    local main_name = target_table.logic["main"]
    if name_map[main_name] then
        target_table.logic["main"] = qload(name_map[main_name])
    end

    local mod_name = target_table.logic["module"]
    if name_map[mod_name] then
        target_table.logic["module"] = qload(name_map[mod_name])
    end
end

return loader