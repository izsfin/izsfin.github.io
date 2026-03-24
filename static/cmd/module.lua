-- Загружаем части системы
local Security = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/md/security.lua", -- Добавь .lua для надежности
    Headers = { ["User-Agent"] = "hux9z/software" }
}).Body)()

local Helpers = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/md/helpers.lua",
    Headers = { ["User-Agent"] = "hux9z/software" }
}).Body)()

local MS_Raw = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/md/module.lua",
    Headers = { ["User-Agent"] = "hux9z/software" }
}).Body)()

-- Инициализация (связываем всё в кучу)
if MS_Raw then
    MS_Raw.Init({
        Security = Security,
        Helpers = Helpers,
        LoadedModules = {}, -- Инициализируем пустую таблицу модулей
        DoClear = function() print("Cleaning...") end, -- Твоя функция очистки
        GetVersion = function() return "1.0.0" end,     -- Твоя версия
        Apply = function(item, box) print("Applying " .. item.Name) end,
        MODULES_PATH = "hux9z/jsx32/modules/",
        DB_PATH = "hux9z/jsx32/db/"
    })
end

return MS_Raw