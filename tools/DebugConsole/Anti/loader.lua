-- // AntiDC.lua
return function()

local AntiDC = {
 sv  = "v1",
 v   = "1.0.1",
        
 BlockedPatterns = {
     "AntiDebugConsole%s*=%s*true",
     "AntiDC%s*=%s*true",
     "blacklistDC%s*=%s*true",
     "DebugConsoleBlacklist%s*=%s*true",
 },
 CheckCode = function(self, code)
  for _, pattern in ipairs(self.BlockedPatterns) do
   if code:match(pattern) then
    return true, pattern
   end
  end
 return false, nil
end,
}
  getgenv()["antiDC" .. AntiDC.sv .. "FS"] = AntiDC
 return AntiDC
end