--[[ JID x PID Joiner || v1.2.0 || by electrox0 ]]

local TeleportService = game:GetService("TeleportService"); local Players = game:GetService("Players"); local setclipboard = setclipboard or print
local function process(mode, result); if mode == "P" then  print("Value : " .. result); elseif mode == "G" then  setclipboard(result)  print("Value copied to clipboard: " .. result); end  end
local args = {...}
for _, input in pairs(args) do; local str = tostring(input); local upperStr = str:upper(); if upperStr:sub(1, 2) == "P=" or upperStr:sub(1, 2) == "G=" then;  local mode = upperStr:sub(1, 1);  local content = str:sub(3);  local result = content:gsub("JID", game.JobId):gsub("PID", tostring(game.PlaceId));  process(mode, result) elseif upperStr == "JID" then  process("P", game.JobId) setclipboard(game.JobId) elseif upperStr == "PID" then  process("P", tostring(game.PlaceId)) setclipboard(tostring(game.PlaceId))
 else local pId = str:match("placeId=(%d+)") or str:match("^%d+$") local jId = str:match("gameInstanceId=([%w%-]+)") or str:match("[%w%-]{20,}") if pId or jId then;  local targetP = tonumber(pId) or game.PlaceId;  print("Value : Attempting teleport to " .. targetP);  if jId then;  TeleportService:TeleportToPlaceInstance(targetP, jId, Players.LocalPlayer);  else;  TeleportService:Teleport(targetP, Players.LocalPlayer);  end
 else print("Value : " .. str) end end end

--[[ Old Joiner || v1.0.1 || by electrox0 ]]
--[[

--Services   

local TeleportService = game:GetService("TeleportService") local Players = game:GetService("Players")
-- In () in end

 local args = {...}
local targetPlaceId = nil
local targetJobId = nil

-- Logic

for _, val in pairs(args) do
 local s = tostring(val)
 local PIDUrl = s:match("placeId=(%d+)")
 local JIDUrl = s:match("gameInstanceId=([%w%-]+)")
    
 if PIDUrl then targetPlaceId = tonumber(PIDUrl) end
 if JIDUrl then targetJobId = JIDUrl end
 
 if tonumber(s) and not targetPlaceId then targetPlaceId = tonumber(s)
 elseif s:find("-") and #s > 20 then targetJobId = s; end end

-- Logic | Place + Job ID Join 
if targetPlaceId and targetJobId then TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Players.LocalPlayer)

-- Logic | PlaceID join
elseif targetPlaceId then TeleportService:Teleport(targetPlaceId, Players.LocalPlayer)

-- Logic | JobId Join
elseif targetJobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, Players.LocalPlayer) end
]]