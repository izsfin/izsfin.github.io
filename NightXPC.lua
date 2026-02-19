--[[  NightX By OverㄨSoft.team                                                                           
  .oooooo.                                               .oooooo..o            .o88o.     .           .                                         
 d8P'  `Y8b                                             d8P'    `Y8            888 `"   .o8         .o8                                         
888      888 oooo    ooo  .ooooo.  oooo d8b oooo    ooo Y88bo.       .ooooo.  o888oo  .o888oo     .o888oo  .ooooo.   .oooo.   ooo. .oo.  .oo.   
888      888  `88.  .8'  d88' `88b `888""8P  `88b..8P'   `"Y8888o.  d88' `88b  888      888         888   d88' `88b `P  )88b  `888P"Y88bP"Y88b  
888      888   `88..8'   888ooo888  888        Y888'         `"Y88b 888   888  888      888         888   888ooo888  .oP"888   888   888   888  
`88b    d88'    `888'    888    .o  888      .o8"'88b   oo     .d8P 888   888  888      888 . .o.   888 . 888    .o d8(  888   888   888   888  
 `Y8bood8P'      `8'     `Y8bod8P' d888b    o88'   888o 8""88888P'  `Y8bod8P' o888o     "888" Y8P   "888" `Y8bod8P' `Y888""8o o888o o888o o888o                                                                                                                                                
]]


local storage = loadstring(game:HttpGet("https://api-winxs.vercel.app/storage"))()
local Library = loadstring(game:HttpGet("https://cdn-winxs.vercel.app/library/cerberus/sourceR"))()
local window = Library.new("wesxware")
window:LockScreenBoundaries(false)
local mainTab = window:Tab("Main")
local mainSection = mainTab:Section("Main")
mainSection:Button("Site", function()
    setclipboard("https://offwenxs.vercel.app")
end)
mainSection:Label("v2.1.55#alpha")

local universalTab = window:Tab("Universal", "rbxassetid://105558355837082")

local func1 = universalTab:Section("Functional #1")
func1:Label("Combat")
func1:Button("ESP | by WA", function() Run.ESPwa() end)
func1:Button("LbEx | rewrite", function() Run.LimbExtender_rewrite() end)
func1:Button("Spin", function() Run.Spin() end)

func1:Label("Movement")
func1:Button("Fly", function() Run.Fly() end)
func1:Button("CFrame", function() Run.Cframe() end)

func1:Label("Multi - Tool")
func1:Button("soon", function() end)

local func2 = universalTab:Section("Functional #2")
func2:Label("Animations")
func2:Button("Gaze | rework", function() Run.Gaze() end)
func2:Button("AFEM | by ???", function() Run.afem() end)

func2:Label("Utillity")
func2:Button("IY | v6.4", function() Run.IY() end)
func2:Button("System Broken", function() Run.SysBroken() end)
func2:Button("External Shift", function() Run.External_Shift() end)
local supportedTab = window:Tab("Supported", "rbxassetid://133172752957923")
local searchSection = supportedTab:Section("Поиск")
local searchBar = searchSection:SearchBar("Search...")
local vdSection = supportedTab:Section("Violence District")
vdSection:Button("VD | by TexRBLX", function() Run.VDTexRBLX() end)
vdSection:Button("VDr | by TexRBLX", function() Run.VDTexRBLXRewrite() end)
vdSection:Button("Disable Stop Emote", function() Run.DisableStopEmote() end)
vdSection:Button("MoonWalk", function() Run.MoonWalk() end)
local evadeSection = supportedTab:Section("Evade")
evadeSection:Button("WhakizashiHubX | repack", function() Run.WhakazhiHubX() end)
evadeSection:Button("Dara Hub | collab", function() Run.DaraHub() end)
local mm2Section = supportedTab:Section("Murder Mystery 2")
mm2Section:Button("Vertex", function() Run.VertexMM2() end)
mm2Section:Button("XHub", function() Run.XHubMM2() end)
mm2Section:Button("OverDriveHub", function() Run.ODHMM2() end)
local lt2Section = supportedTab:Section("Lumber Tycoon 2")
lt2Section:Button("Luaware", function() Run.KronHub() end)
lt2Section:Button("Kron Hub", function() Run.LuaWare() end)
lt2Section:Button("School Hub", function() Run.SchoolHub() end)
