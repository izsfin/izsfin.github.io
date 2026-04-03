--[[ JID x PID Joiner || v1.1.0 || by electrox0 ]]
--[[ Сервисы для скрипта ]] 
local TeleportService = game:GetService("TeleportService"); local LogService = game:GetService("LogService"); local setclipboard = setclipboard or print

local function process(mode, PID, JID)
 local p = PID or game.PlaceId
  local j = JID or game.JobId
  local result = ""
  if PID and JID then result = p .. " | " .. j
  elseif PID then result = tostring(p)
  elseif JID then result = tostring(j); end
  if mode == "P" then print("Value : " .. result)
  elseif mode == "G" then setclipboard(result) print("Value copied to clipboard"); end end

local args = {...}

for _, input in pairs(args) do
  local str = tostring(input)
  local mode = str:sub(1, 2):upper()
  local cleanStr = str:sub(3)

  if mode == "P=" or mode == "G=" then
   local m = mode:sub(1, 1) -- 'P' или 'G'
   local PID = cleanStr:match("(%d+)")
   local JID = cleanStr:match("([%w%-]{20,})")    
   process(m, PID, JID)

--[[ Одиночные команды ]]
  elseif str == "JID" then process("P", nil, game.JobId) setclipboard(game.JobId)
  elseif str == "PID" then process("P", game.PlaceId, nil) setclipboard(tostring(game.PlaceId))
 else print("Value : " .. str) end
end

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