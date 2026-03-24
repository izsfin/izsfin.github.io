local loader = {}

-- Внутренняя таблица соответствий имен и путей на сервере
local name_map = {
    ["xms_main_core"]   = "ximeax/logic",
    ["xms_security_v2"] = "ximeax/module",
    ["callname_test"]   = "ximeax/test_logic"
}

function loader.fill(target_table, ua, base)
    local function qload(path)
        local res = game:HttpGet(base .. path)
        return loadstring(res)()
    end

    -- 1. Грузим статику по обычным путям
    target_table.library = qload("static/cmd")
    target_table.meta    = qload("ximeax/MIxConfig")

    -- 2. Динамическая загрузка логики по "callname"
    -- Проверяем, что написано в target_table.logic.main
    local main_callname = target_table.logic.main
    if name_map[main_callname] then
        target_table.logic.main = qload(name_map[main_callname])
    else
        warn("Loader || Unknown callname for main: " .. tostring(main_callname))
    end

    local module_callname = target_table.logic.module
    if name_map[module_callname] then
        target_table.logic.module = qload(name_map[module_callname])
    end
end

return loader