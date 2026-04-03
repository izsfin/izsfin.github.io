--[[ Arg Joiner || by electrox0]]
--[[ Services ]]    local TeleportService = game:GetService("TeleportService") local Players = game:GetService("Players")
--[[ In () in end]] local args = {...}
local targetPlaceId = nil
local targetJobId = nil

--[[ Logic]]
for _, val in pairs(args) do
 local s = tostring(val)
 local pIdUrl = s:match("placeId=(%d+)")
 local jIdUrl = s:match("gameInstanceId=([%w%-]+)")
    
 if pIdUrl then targetPlaceId = tonumber(pIdUrl) end
 if jIdUrl then targetJobId = jIdUrl end
 
 if tonumber(s) and not targetPlaceId then targetPlaceId = tonumber(s)
 elseif s:find("-") and #s > 20 then targetJobId = s; end end

--[[ Logic | Place + Job ID Join ]]   if targetPlaceId and targetJobId then TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Players.LocalPlayer)
--[[ Logic | PlaceID join        ]]   elseif targetPlaceId then TeleportService:Teleport(targetPlaceId, Players.LocalPlayer)
--[[ Logic | JobId Join          ]]   elseif targetJobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, Players.LocalPlayer) end