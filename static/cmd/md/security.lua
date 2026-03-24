-- [ js SECURITY MODULE ]
-- Загружается с сервера и подключается к основному скрипту

local HttpService = game:GetService("HttpService")
local Security = {}

-- [ КОНФИГ ]
local SECURITY_URL   = "https://ethereos-api.vercel.app/xms/security"
local VERIFIED_URL   = "https://ethereos-api.vercel.app/xms/verified"
local DISCORD        = ".gg/TRPZg4Xfkq"
local ROOT_PATH      = "hux9z/JS/x³²/"
local MODULES_PATH   = ROOT_PATH .. "modules/"
local PROTECTED_PATHS = {
    ROOT_PATH .. "config",
    ROOT_PATH .. "db",
    ROOT_PATH .. "security",
}
local PROTECTED_GLOBALS = {
    "js",
    "MainHandler",
    "DoClear",
    "Apply",
}

-- [ ЗАГРУЗКА С СЕРВЕРА ]
local securityData  = nil
local verifiedData  = nil

local function FetchSecurity()
    local s, r = pcall(game.HttpGet, game, SECURITY_URL)
    if s and r then
        local ok, data = pcall(function() return HttpService:JSONDecode(r) end)
        if ok then securityData = data end
    end
end

local function FetchVerified()
    local s, r = pcall(game.HttpGet, game, VERIFIED_URL)
    if s and r then
        local ok, data = pcall(function() return HttpService:JSONDecode(r) end)
        if ok then verifiedData = data end
    end
end

-- [ ПРОВЕРКА ВЕРИФИКАЦИИ ]
function Security.IsVerified(author)
    if not verifiedData then return false end
    for _, a in pairs(verifiedData) do
        if tostring(a):lower() == tostring(author):lower() then return true end
    end
    return false
end

-- [ ОШИБКИ ]
local function ThrowError(code, msg, copyDiscord)
    warn(code .. " || " .. msg)
    if copyDiscord then
        pcall(setclipboard, "https://discord.com/" .. DISCORD)
    end
end

-- [ ЗАЩИТА ПУТЕЙ ]
-- Редирект вместо ошибки (093)
function Security.SafePath(moduleName, requestedPath, author)
    local allowedRoot = MODULES_PATH .. (moduleName or author or "unknown") .. "/"

    -- Проверяем защищённые пути
    for _, blocked in pairs(PROTECTED_PATHS) do
        if requestedPath:sub(1, #blocked) == blocked then
            -- 093: не ошибка, редиректим в папку модуля
            local filename = requestedPath:match("[^/]+$") or "file"
            local redirected = allowedRoot .. filename
            return redirected
        end
    end

    -- Проверяем что модуль не лезет в чужую папку модуля
    if requestedPath:sub(1, #MODULES_PATH) == MODULES_PATH then
        if requestedPath:sub(1, #allowedRoot) ~= allowedRoot then
            -- 094: пытается читать чужую папку
            local targetMod = requestedPath:match(MODULES_PATH .. "([^/]+)")
            ThrowError(
                "094 Fatal Error",
                "'" .. (moduleName or "Unknown") .. "' attempting to read '" .. (targetMod or "Unknown") .. "' folder",
                false
            )
            return nil -- блокируем
        end
    end

    return requestedPath -- путь разрешён
end

-- [ ЗАЩИТА ГЛОБАЛОВ ]
-- Снимок оригинальных значений
local _originalGlobals = {}
local function SnapshotGlobals()
    for _, name in pairs(PROTECTED_GLOBALS) do
        _originalGlobals[name] = getgenv()[name]
    end
end

-- Проверка что никто не перезаписал глобалы
local function CheckGlobals(moduleName)
    for _, name in pairs(PROTECTED_GLOBALS) do
        if getgenv()[name] ~= _originalGlobals[name] then
            -- Восстанавливаем
            getgenv()[name] = _originalGlobals[name]

            if name == "js" then
                ThrowError(
                    "092 Fatal Error",
                    "'" .. (moduleName or "Unknown") .. "' attempting to hook getgenv().js [ Please, change hook function to another in your module ]",
                    true
                )
            else
                ThrowError(
                    "092 Fatal Error",
                    "'" .. (moduleName or "Unknown") .. "' attempting to hook built-in function '" .. name .. "'",
                    true
                )
            end

            return false
        end
    end
    return true
end

-- [ ЗАЩИТА CALLSYNTAX ]
local registeredSyntax = { js = "built-in" } -- js всегда занят

function Security.RegisterCallsyntax(moduleName, syntax)
    if not syntax or syntax == "" then return true end

    -- Попытка занять js
    if syntax:lower() == "js" then
        ThrowError(
            "091 Fatal Error",
            "'" .. moduleName .. "' attempts to override built-in callsyntax js() [ Please, change callsyntax to another if owner of " .. moduleName .. " you ]",
            true
        )
        return false
    end

    -- Конфликт с другим модулем (083)
    if registeredSyntax[syntax] then
        ThrowError(
            "083 Fatal Error",
            "Callsyntax from '" .. moduleName .. "' conflicts with '" .. registeredSyntax[syntax] .. "' || Unload first: js('unload = " .. registeredSyntax[syntax] .. "')",
            false
        )
        return false
    end

    registeredSyntax[syntax] = moduleName
    return true
end

function Security.UnregisterCallsyntax(moduleName)
    for syntax, owner in pairs(registeredSyntax) do
        if owner == moduleName then
            registeredSyntax[syntax] = nil
        end
    end
end

-- [ ПРОВЕРКА ВЕРСИИ МОДУЛЯ ]
function Security.CheckVersion(moduleName, sversion, currentVersion)
    if not sversion or sversion == "" then return true end

    -- Простое сравнение версий (vX.X.X)
    local function parseVer(v)
        local a, b, c = tostring(v):match("v?(%d+)%.(%d+)%.(%d+)")
        return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
    end

    local sA, sB, sC = parseVer(sversion)
    local cA, cB, cC = parseVer(currentVersion)

    local supported = (cA > sA) or (cA == sA and cB > sB) or (cA == sA and cB == sB and cC >= sC)

    if not supported then
        ThrowError(
            "097 Error",
            "'" .. moduleName .. "' requires js " .. sversion .. "+ (current: " .. currentVersion .. ")",
            false
        )
        return false
    end

    return true
end

-- [ ПРОВЕРКА СТРУКТУРЫ МОДУЛЯ ]
local REQUIRED_FIELDS = { "NameModule", "VersionModule", "Author", "library" }

function Security.ValidateModule(data, moduleName)
    local valid = true
    for _, field in pairs(REQUIRED_FIELDS) do
        if data[field] == nil then
            ThrowError(
                "096 Error",
                "Invalid module structure in '" .. (moduleName or "Unknown") .. "' || Missing: " .. field,
                false
            )
            valid = false
        end
    end
    return valid -- возвращаем true даже если что-то отсутствует — грузим что работает
end

-- [ SANDBOX ДЛЯ КОДА МОДУЛЯ ]
-- Изолированное окружение для FunctionCode
function Security.CreateSandbox(moduleName, author, allowedPath)
    local sandbox = {}

    -- Разрешённые глобалы
    local allowed = {
        "game", "workspace", "script", "math", "table", "string",
        "pairs", "ipairs", "next", "select", "type", "tostring", "tonumber",
        "pcall", "xpcall", "error", "warn", "print", "wait", "task",
        "Instance", "Vector3", "CFrame", "Color3", "Enum", "UDim2", "UDim",
        "tick", "os", "coroutine", "unpack",
    }

    for _, name in pairs(allowed) do
        sandbox[name] = getgenv()[name]
    end

    -- Безопасный writefile
    sandbox.writefile = function(path, content)
        local safePath = Security.SafePath(moduleName, path, author)
        if safePath then
            pcall(writefile, safePath, content)
        end
    end

    -- Безопасный readfile
    sandbox.readfile = function(path)
        local safePath = Security.SafePath(moduleName, path, author)
        if safePath then
            local s, r = pcall(readfile, safePath)
            return s and r or nil
        end
        return nil
    end

    -- Безопасный isfile
    sandbox.isfile = function(path)
        local safePath = Security.SafePath(moduleName, path, author)
        if safePath then
            local s, r = pcall(isfile, safePath)
            return s and r or false
        end
        return false
    end

    -- Безопасный makefolder
    sandbox.makefolder = function(path)
        local safePath = Security.SafePath(moduleName, path, author)
        if safePath then
            pcall(makefolder, safePath)
        end
    end

    -- Запрет на getgenv / hookfunction
    sandbox.getgenv     = function() ThrowError("092 Fatal Error", "'" .. moduleName .. "' attempting to hook getgenv().js", true) end
    sandbox.hookfunction = function() ThrowError("092 Fatal Error", "'" .. moduleName .. "' attempting to hook built-in function", true) end

    sandbox._G = sandbox
    setmetatable(sandbox, { __index = function(_, k) return nil end })

    return sandbox
end

-- Инициализация при загрузке
FetchVerified()
SnapshotGlobals()

return Security