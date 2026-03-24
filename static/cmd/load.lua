local http = http or syn and syn.request or request

-- Генерируем уникальный ID сессии
local function rnd()
    return math.random(100000, 999999)
end

local sessionID = rnd() .. "_" .. rnd() .. "_" .. os.time()

-- Проверяем был ли уже использован
local flagFile = "xms_session.lock"
local alreadyUsed = false

pcall(function()
    local f = readfile(flagFile)
    if f and f ~= "" then
        alreadyUsed = true
    end
end)

if alreadyUsed then
    warn("XMS || Session already used!")
    return nil
end

-- Записываем флаг
pcall(function()
    writefile(flagFile, sessionID)
end)

-- Строим уникальное имя таблицы
local n1, n2 = rnd(), rnd()

local UA, BASE = loadstring(http({ Url = "https://nekoq.vercel.app/static/cmd/llUA" }).Body)()
if not UA or not BASE then
    UA   = "hux9z/software"
    BASE = "https://nekoq.vercel.app/static/cmd"
end

local function fetch(path)
    return loadstring(http({ Url = BASE .. path, Headers = { ["User-Agent"] = UA } }).Body)()
end

local pkg = {}
pkg.meta_load    = fetch("/meta")
pkg.library_load = fetch("/library")
pkg.logic_load   = fetch("/logic")
pkg.module_load  = fetch("/module")
pkg._sid         = sessionID
pkg._tag         = "using" .. n1 .. "from" .. n2 .. "loadv2"

return pkg