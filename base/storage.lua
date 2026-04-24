getgenv().Run = getgenv().Run or {}
local function exec(url) local success, code = pcall(game.HttpGet, game, url) if success and code then local func, err = loadstring(code) if func then func() else warn("Failed to compile script: " .. tostring(err)) end else warn("Failed to load script. Link: " .. tostring(url)) end end

Run.WAESP = function() exec("https://raw.makito.workers.dev/scripts/combat/WAesp.lua") end
Run.LimbExtender_rewrite = function() exec("https://raw.makito.workers.dev/scripts/combat/LimbExtender/minify.lua") end
Run.Spin = function() exec("https://raw.makito.workers.dev/scripts/combat/Spin.lua") end
Run.Fly = function() exec("https://raw.makito.workers.dev/scripts/movement/fly.lua") end
Run.Cframe = function() exec("https://raw.makito.workers.dev/scripts/movement/cframe-speed/minify.lua") end

Run.Gaze = function() exec("https://raw.makito.workers.dev/scripts/animations/Gaze.lua") end
Run.afem = function() exec("https://raw.makito.workers.dev/scripts/animations/AFEM.lua") end
Run.IY = function() exec("https://raw.makito.workers.dev/scripts/fe-scripts/infinity-yield.lua") end
Run.SysBroken = function() exec("https://raw.makito.workers.dev/scripts/sysbrokenU.lua") end
Run.External_Shift = function() exec("https://raw.makito.workers.dev/scripts/movement/external-shift.lua") end
-- Multi — Tool
Run.ExecutorBydzenero = function() exec("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/executor.lua") end
Run.Executor = function() exec("https://example.com") end
Run.OldConsoleBywally = function() exec("https://raw.githubusercontent.com/infyiff/backup/main/console.lua") end
Run.DexByIY = function() exec("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua") end


-- Games
Run.VDTexRBLX = function() exec("https://raw.makito.workers.dev/scripts/games/loadviolence-district/TexRBLX-script.lua") end
Run.VDTexRBLXRewrite = function() exec("https://raw.makito.workers.dev/scripts/games/violence-district/TexRBLX-Rewrite.lua") end
Run.DisableStopEmote = function() exec("https://raw.makito.workers.dev/scripts/games/violence-district/DisableStopEmote.lua") end
Run.MoonWalk = function() exec("https://raw.makito.workers.dev/scripts/games/violence-district/MoonWalk.lua") end
-- EVADE
Run.WhakazhiHubX = function() exec("https://raw.makito.workers.dev/scripts/games/evade/WhakizashiHubX.lua") end
Run.DaraHub = function() exec("https://darahub.vercel.app/main.lua") end -- COLLAB
Run.ODHMM2 = function() exec("https://api.overdrivehub.xyz/v1/auth") end
Run.XHubMM2 = function() exec("https://raw.githubusercontent.com/Au0yX/Community/main/XhubMM2") end
Run.VertexMM2 = function() exec("https://raw.smokingscripts.org/vertex.lua") end


Run.KronHub = function() exec("https://raw.githubusercontent.com/DevKron/Kron_Hub/main/version_1.0") end
Run.LuaWare = function() exec("https://raw.githubusercontent.com/frencaliber/LuaWareLoader.lw/main/luawareloader.wtf") end
Run.SchoolHub = function() exec("https://raw.githubusercontent.com/IHateSchoolIsCool/FuckCheapShops/main/Schoolhub%20Selector") end