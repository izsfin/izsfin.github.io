-- XMS | Slim Loader

local Library = {
    {
        Class = "Character",
		Subclass = "Head",
        Name = "Anime Woman",
        MeshID = "rbxassetid://76877570105127",
        TextureID = "rbxassetid://121827081031002",
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Character",
		Subclass = "Head",
        Name = "Sleek Tire Girl",
        MeshID = "rbxassetid://96040719638479",
        TextureID = "rbxassetid://108395821618310",
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Character",
		Subclass = "Head",
        Name = "Pal Face",
        MeshID = "rbxassetid://107425611375451",  
        TextureID = "rbxassetid://73445145632944", 
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Character",
		Subclass = "Head",
        Name = "Bored Moe",
        MeshID = "rbxassetid://82135150215758",
        TextureID = "rbxassetid://77885674031737",
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Accessory",
		Subclass = "Face",
        Name = "Blind Fold",
        Weld = "Head",
        MeshID = "rbxassetid://120177601931635",
        TextureID = "rbxassetid://111644589425325",
        CFrame = CFrame.new(0, -0.2, 0) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
		Subclass = "Face",
        Name = "Black Mask",
        Weld = "Head",
        MeshID = "rbxassetid://138741421741528",
        TextureID = "rbxassetid://102873858608892",
        CFrame = CFrame.new(0, 0, 0.55) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
		Subclass = "Torso",
        Name = "White Vest",
        Weld = "Torso",
        MeshID = "rbxassetid://85934571755429",
        TextureID = "rbxassetid://85523839045578", 
        CFrame = CFrame.new(0, -0.22, 0.1) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Cap",
        Weld = "Head",
        MeshID = "rbxassetid://92976453142475",
        TextureID = "rbxassetid://84600492178264",
        CFrame = CFrame.new(0, -0.4, -0.05) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Black Cat Ears",
        Weld = "Head",
        MeshID = "rbxassetid://128534799696292",
        TextureID = "rbxassetid://102873858608892",
        CFrame = CFrame.new(0, -0.8, 0.1) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Emo Spiked Shades",
        Weld = "Head",
        MeshID = "rbxassetid://17154559796",
        TextureID = "rbxassetid://17154478293",
        CFrame = CFrame.new(0, -0.2, 0.2) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Back Tail",
        Weld = "Torso",
        MeshID = "rbxassetid://85052393126449",
        TextureID = "rbxassetid://76742493960027",
        CFrame = CFrame.new(0, 0.7, -0.7) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Two Time Back",
        Weld = "Torso",
        MeshID = "rbxassetid://102535235285318",
        TextureID = "rbxassetid://132597092841215",
        CFrame = CFrame.new(0, 0.7, -0.8) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Script",
        Name = "OldDXB",
        URL = "https://weh-face.vercel.app/old-DXBRE",
		ReqPlaceID = 0
    },
    {
        Class = "Body",
        Name = "Custom",
        Torso = "rbxassetid://27493004",
        LeftArm = "rbxassetid://27400132",
        RightArm = "rbxassetid://27400198",
        LeftLeg = "rbxassetid://27493033",
        RightLeg = "rbxassetid://27493073",
		ReqPlaceID = 0
    },
{
        Class = "Body",
        Name = "Guns&Alien",
        Torso = "rbxassetid://32332055",
        LeftArm = "rbxassetid://32331863",
        RightArm = "rbxassetid://32331968",
        LeftLeg = "rbxassetid://27493033",
        RightLeg = "rbxassetid://27493073",
        ReqPlaceID = 0
    },
    {
        Class = "Body",
        Name = "Robloxian 2.0",
        Torso = "rbxassetid://27111894",
        LeftArm = "rbxassetid://27111419",
        RightArm = "rbxassetid://27111864",
        LeftLeg = "rbxassetid://27111857",
        RightLeg = "rbxassetid://27111882",
        ReqPlaceID = 0
    },
    {
        Class = "Body",
        Name = "Superhero",
        Torso = "rbxassetid://32328670",
        LeftArm = "rbxassetid://32328397",
        RightArm = "rbxassetid://32328563",
        LeftLeg = "rbxassetid://32328520",
        RightLeg = "rbxassetid://32328627",
        ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Maid",
        ShirtID = "rbxassetid://8913691200",
        PantsID = "rbxassetid://8913657959",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Full White",
        ShirtID = "rbxassetid://85523839045578",
        PantsID = "rbxassetid://11822355274",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Black Bape",
        ShirtID = "rbxassetid://12479984354",
        PantsID = "rbxassetid://86502284322720",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Blue Bape #1",
        ShirtID = "rbxassetid://104101450723927",
        PantsID = "rbxassetid://13548583082",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Blue Bape #2",
        ShirtID = "rbxassetid://1480219794",
        PantsID = "rbxassetid://85218720417005",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Purple Bape #1",
        ShirtID = "rbxassetid://12594352160",
        PantsID = "rbxassetid://4748004844", 
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Purple Bape #2",
        ShirtID = "rbxassetid://12594352160",
        PantsID = "rbxassetid://2032528065", 
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Classic Camo",
        ShirtID = "rbxassetid://5349579058",
        PantsID = "rbxassetid://5545983180",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Blue Camo",
        ShirtID = "rbxassetid://7335989658",
        PantsID = "rbxassetid://7336069002",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Black Camo #1",
        ShirtID = "rbxassetid://12433294632",
        PantsID = "rbxassetid://13284675767",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Black Camo #2",
        ShirtID = "rbxassetid://13284655735",
        PantsID = "rbxassetid://13284675767",
		ReqPlaceID = 0
    },
    {
        Class = "Outfit",
        Name = "Jester",
        ShirtID = "rbxassetid://6280071638",
        PantsID = "rbxassetid://11760797553",
		ReqPlaceID = 0
    },
	{
		Class = "Outfit",
		Name = "NervousLeader",
		ShirtID = "rbxassetid://13597720043",
		PantsID = "rbxassetid://10623172306",
		ReqPlaceID = 0
	},
    {
        Class = "Outfit",
        Name = "Classic",
        ShirtID = "rbxassetid://6067501459",
        PantsID = "rbxassetid://13692756757",
		ReqPlaceID = 0
    },
    {
        Class = "Accessory",
		SubClass="Head",
        Name = "Hat",
        Weld = "Head",
        MeshID = "rbxassetid://73083430479187",
        TextureID = "rbxassetid://104381302798685",
        CFrame = CFrame.new(-0.013, 0.1, -0.005),
		ReqPlaceID = 0
    },
    {
        Class = "Animation",
        Name = "New",
        IdleID = "rbxassetid://0",
        WalkID = "rbxassetid://0",
        RunID = "rbxassetid://0",
        JumpID = "rbxassetid://0",
        FallID = "rbxassetid://0",
        PoseID = "rbxassetid://0",
		ReqPlaceID = 0
    },
    {
        Class = "Face",
        Name = "Default",
        ID = "rbxassetid://0",
		ReqPlaceID = 0
	}
}

-- 1. llUA
local UA, BASE = loadstring(http.request({ Url = "https://wexly-api.vercel.app/ximeax/llUA" }).Body)()
if not UA or not BASE then UA   = "ximeax/software" BASE = "https://wexly-api.vercel.app/" end

-- 2. mcfg
local miXconf = loadstring(http.request({ Url     = BASE .. "ximeax/MIxConfig", Headers = { ["User-Agent"] = UA } }).Body)()
if not miXconf then warn("XMS || MIxConfig not answer, please try later!"); return end
print(miXconf.project_name .. " || Loading | " .. miXconf.project_vers)

-- 3. logic
local Logic = loadstring(http.request({ Url     = BASE .. "ximeax/logic", Headers = { ["User-Agent"] = UA } }).Body)()
if not Logic then miXconf:logic_down(); return end

-- 4. modules
--local ModuleSystem = loadstring(http.request({ Url     = BASE .. "ximeax/module", Headers = { ["User-Agent"] = UA } }).Body)()
-- 4. modules
local ModuleSystem = nil
--[[
if not ModuleSystem then miXconf:md_down() ModuleSystem = loadstring(http.request({ Url     = BASE .. "ximeax/md/module", Headers = { ["User-Agent"] = UA } }).Body)()
end]]

Logic.Start(Library, miXconf, ModuleSystem, UA, BASE)
print(miXconf.project_name .. " || Loaded! | " .. miXconf.project_vers)