-- Prototype Phone | SSl.lua
-- xELO LLC / SyntoriMS

local SS   = getgenv().PP.SS
local HttpService = game:GetService("HttpService")

local SSl = {}

-- Генерация PPsid
local function genID(len)
    local chars = "0123456789"
    local s = ""
    for i = 1, len do
        local idx = math.random(1, #chars)
        s = s .. chars:sub(idx, idx)
    end
    return s
end

-- Генерация PPNumber (6 знаков)
local function genNumber()
    return tostring(math.random(100000, 999999))
end

-- Путь к файлу профиля
local ROOT     = getgenv().PP.Root
local SELFFILE = ROOT .. "self.json"

-- Загрузить или создать профиль
function SSl:GetOrCreateSelf()
    if isfile(SELFFILE) then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(SELFFILE))
        if ok and data.ppsid then return data end
    end

    -- Новый профиль
    local username = game.Players.LocalPlayer.Name
    local playerid = tostring(game.Players.LocalPlayer.UserId)
    local ppsid    = genID(12)
    local ppnumber = genNumber()

    local profile = {
        ppsid    = ppsid,
        username = username,
        ppnumber = ppnumber,
        playerid = playerid,
    }

    -- Регистрация на сервере
    SS.Request("POST", "/user/register", profile)

    -- Сохранить локально
    writefile(SELFFILE, HttpService:JSONEncode(profile))

    return profile
end

-- Поиск юзера по username
function SSl:FindUser(username)
    local data = SS.Request("GET", "/user/find?username=" .. username, nil)
    if data and data.found then return data.user end
    return nil
end

-- Отправить сообщение
local lastSend = 0
function SSl:SendMessage(receiver_ppsid, message)
    local now = os.clock()
    if now - lastSend < 10 then
        return false, "cooldown"
    end
    lastSend = now

    local self_profile = self:GetOrCreateSelf()
    local ts = os.date("%H:%M:%S_%d.%m.%Y")

    -- Сохранить локально
    local histPath = ROOT .. "History/Messages/"
    local fname    = histPath .. receiver_ppsid .. ".json"
    local history  = {}

    if isfile(fname) then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(fname))
        if ok then history = data end
    end

    table.insert(history, {
        sender    = self_profile.ppsid,
        message   = message,
        timestamp = ts,
    })

    writefile(fname, HttpService:JSONEncode(history))

    -- Отправить на сервер
    SS.Request("POST", "/message/send", {
        sender_ppsid   = self_profile.ppsid,
        receiver_ppsid = receiver_ppsid,
        message        = message,
        timestamp      = ts,
    })

    return true
end

-- Загрузить историю с контактом
function SSl:GetHistory(contact_ppsid)
    local self_profile = self:GetOrCreateSelf()
    local data = SS.Request("GET", 
        "/message/history?a=" .. self_profile.ppsid .. "&b=" .. contact_ppsid .. "&limit=100",
        nil)
    if data then return data.messages end
    return {}
end

-- Добавить контакт
function SSl:AddContact(contact_ppsid)
    local self_profile = self:GetOrCreateSelf()
    SS.Request("POST", "/contact/add", {
        owner_ppsid   = self_profile.ppsid,
        contact_ppsid = contact_ppsid,
    })

    -- Сохранить локально
    local path  = ROOT .. "Contacts/All_Contacts/"
    local fname = path .. contact_ppsid .. ".ppcntc"
    local user  = SSl:FindUser_byPPsid(contact_ppsid)
    if user then
        writefile(fname, HttpService:JSONEncode(user))
    end
end

-- Получить список контактов
function SSl:GetContacts()
    local self_profile = self:GetOrCreateSelf()
    local data = SS.Request("GET", "/contact/list?ppsid=" .. self_profile.ppsid, nil)
    if data then return data.contacts end
    return {}
end

return SSl