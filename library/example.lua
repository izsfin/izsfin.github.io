local UI = loadstring(game:HttpGet("https://weakez.pages.dev/$/library/rageX.lua"))()

local win = UI.new{
    Title   = "Hitbox Extender",
    Icon    = "107904589783906",
    Keybind = "F2",
}

local s = win:Section("SETTINGS")

s:Toggle("Team Check", true, function(v) end)
s:Slider("Limb Size", 5, 50, 15, 0.5, function(v) end)
s:Dropdown("Target Limb", {"HumanoidRootPart", "Head"}, "HumanoidRootPart", function(v) end)
s:TextBox("Введи значение...", function(text, enter) end)