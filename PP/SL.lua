-- Prototype Phone | SSl.lua
-- xELO LLC / SyntoriMS

local SS          = getgenv().PP.SS
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SSl = {}

-- Пути
local function getRoot()
    local pid = tostring(LocalPlayer.UserId)
    local root = "xELO LLC/PP/Profiles/" .. pid .. "/"
    local folders = {
        "xELO LLC/",
        "xELO LLC/PP/",
        "xELO LLC/PP/Profiles/",
        root,
        root .. "History/",
        root .. "History/Messages/",
        root .. "Contacts/",
        root .. "Contacts/All_Contacts/",
    }
    for _, f in ipairs(folders) do
        if not isfolder(f) then makefolder(f) end
    end
    return root
end

local function genID(len)
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local s = ""
    for i = 1, len do
        s = s .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return s
end

local function genNumber()
    return tostring(math.random(100000, 999999))
end

local function readJSON(path)
    if not isfile(path) then return nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if ok then return data end
    return nil
end

local function writeJSON(path, data)
    writefile(path, HttpService:JSONEncode(data))
end

-- Профиль
function SSl:GetOrCreateSelf()
    if getgenv().PP_PROFILE then return getgenv().PP_PROFILE end

    local root = getRoot()
    local path = root .. "self.json"
    local data = readJSON(path)

    if data and data.ppsid then
        getgenv().PP_PROFILE = data
        return data
    end

    -- Новый профиль
    local profile = {
        ppsid    = genID(12),
        username = LocalPlayer.Name,
        ppnumber = genNumber(),
        playerid = tostring(LocalPlayer.UserId),
    }

    SS.Request("POST", "/user/register", profile)
    writeJSON(path, profile)
    getgenv().PP_PROFILE = profile
    return profile
end

-- Очередь неотправленных сообщений
local QUEUE_KEY = "msg_queue"

local function getQueue(root)
    return readJSON(root .. "msg_queue.json") or {}
end

local function saveQueue(root, queue)
    writeJSON(root .. "msg_queue.json", queue)
end

-- Добавить сообщение в очередь (локально)
function SSl:QueueMessage(receiver_ppsid, message)
    local root    = getRoot()
    local profile = self:GetOrCreateSelf()
    local ts      = os.date("%H:%M:%S_%d.%m.%Y")
    local queue   = getQueue(root)

    table.insert(queue, {
        sender_ppsid   = profile.ppsid,
        receiver_ppsid = receiver_ppsid,
        message        = message,
        timestamp      = ts,
    })

    saveQueue(root, queue)

    -- Сохранить в локальную историю сразу
    local hpath   = root .. "History/Messages/" .. receiver_ppsid .. ".json"
    local history = readJSON(hpath) or {}
    table.insert(history, {
        sender    = profile.ppsid,
        message   = message,
        timestamp = ts,
        sent      = false,
    })
    writeJSON(hpath, history)
end

-- Отправить очередь на сервер
function SSl:FlushQueue()
    local root  = getRoot()
    local queue = getQueue(root)
    if #queue == 0 then return end

    local failed = {}
    for _, msg in ipairs(queue) do
        local ok = SS.Request("POST", "/message/send", msg)
        if not ok then
            table.insert(failed, msg)
        end
    end

    saveQueue(root, failed)
end

-- Поллинг новых сообщений (каждые 5с)
local lastMessageID = 0

function SSl:PollMessages(callback)
    local profile = self:GetOrCreateSelf()
    local root    = getRoot()

    task.spawn(function()
        while true do
            task.wait(5)
            local data = SS.Request("GET",
                "/message/poll?receiver=" .. profile.ppsid .. "&after=" .. lastMessageID,
                nil)

            if data and data.messages then
                for _, msg in ipairs(data.messages) do
                    if msg.id > lastMessageID then
                        lastMessageID = msg.id
                    end

                    -- Сохранить локально
                    local hpath   = root .. "History/Messages/" .. msg.sender_ppsid .. ".json"
                    local history = readJSON(hpath) or {}
                    table.insert(history, {
                        sender    = msg.sender_ppsid,
                        message   = msg.message,
                        timestamp = msg.timestamp,
                        sent      = true,
                    })
                    writeJSON(hpath, history)

                    -- Колбек для UI
                    if callback then
                        callback(msg)
                    end
                end
            end
        end
    end)
end

-- Получить историю с контактом
function SSl:GetHistory(contact_ppsid)
    local root  = getRoot()
    local hpath = root .. "History/Messages/" .. contact_ppsid .. ".json"
    return readJSON(hpath) or {}
end

-- Поиск юзера по username
function SSl:FindUser(username)
    local data = SS.Request("GET", "/user/find?username=" .. username, nil)
    if data and data.found then return data.user end
    return nil
end

-- Добавить контакт
function SSl:AddContact(user)
    local root    = getRoot()
    local profile = self:GetOrCreateSelf()

    SS.Request("POST", "/contact/add", {
        owner_ppsid   = profile.ppsid,
        contact_ppsid = user.ppsid,
    })

    local fname = root .. "Contacts/All_Contacts/" .. user.username .. ".ppcntc"
    writeJSON(fname, user)
end

-- Получить контакты (локально)
function SSl:GetContacts()
    local root  = getRoot()
    local path  = root .. "Contacts/All_Contacts/"
    local files = listfiles(path)
    local contacts = {}

    for _, fpath in ipairs(files) do
        local data = readJSON(fpath)
        if data then
            table.insert(contacts, data)
        end
    end

    return contacts
end

-- Инициализация: flush при старте и при выходе
function SSl:Init()
    self:GetOrCreateSelf()
    self:FlushQueue() -- отправить неотправленное с прошлой сессии

    game:BindToClose(function()
        self:FlushQueue()
    end)
end

return SSl