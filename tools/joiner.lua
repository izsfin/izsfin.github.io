local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local input = ... -- Получаем наше "value"

if not input then return end

-- 1. Если передали полную ссылку roblox://...
local pIdFromUrl = input:match("placeId=(%d+)")
local jIdFromUrl = input:match("gameInstanceId=([%w%-]+)")

if pIdFromUrl and jIdFromUrl then
    TeleportService:TeleportToPlaceInstance(tonumber(pIdFromUrl), jIdFromUrl, Players.LocalPlayer)

-- 2. Если передали JobID (выглядит как 4a68fd58...)
elseif #input > 20 and input:find("-") then
    -- ВАЖНО: Чтобы зайти по JobID, нужно знать PlaceID. 
    -- Если ты передал ТОЛЬКО JobID, скрипт попробует текущий PlaceId
    TeleportService:TeleportToPlaceInstance(game.PlaceId, input, Players.LocalPlayer)

-- 3. Если передали только PlaceID (число)
elseif tonumber(input) then
    TeleportService:Teleport(tonumber(input), Players.LocalPlayer)
end