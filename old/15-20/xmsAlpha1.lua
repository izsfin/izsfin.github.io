-- XMS | Loader
-- wexly-api.vercel.app/ximeax/loader

local BASE    = "https://wexly-api.vercel.app/"
local UA      = "ximeax/software"
local Library = {
    {
        Class = "Head",
        Name = "FaceHead",
        MeshID = "rbxassetid://76877570105127",
        TextureID = "rbxassetid://121827081031002",
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Head",
        Name = "Sleek Tire G",
        MeshID = "rbxassetid://96040719638479",
        TextureID = "rbxassetid://108395821618310",
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Head",
        Name = "Pal Face",
        MeshID = "rbxassetid://107425611375451",  
        TextureID = "rbxassetid://73445145632944", 
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Head",
        Name = "Bored Moe",
        MeshID = "rbxassetid://82135150215758",
        TextureID = "rbxassetid://77885674031737",
        Scale = Vector3.new(1.0, 1.0, 1.0),
		ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Face Blind Fold",
        Weld = "Head",
        MeshID = "rbxassetid://120177601931635",
        TextureID = "rbxassetid://111644589425325",
        CFrame = CFrame.new(0, -0.2, 0) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "White Vest",
        Weld = "Torso",
        MeshID = "rbxassetid://85934571755429",
        TextureID = "rbxassetid://85523839045578", 
        CFrame = CFrame.new(0, -0.22, 0.1) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
        ReqPlaceID = 0
    },
    {
        Class = "Accessory",
        Name = "Black Mask",
        Weld = "Head",
        MeshID = "rbxassetid://138741421741528",
        TextureID = "rbxassetid://102873858608892",
        CFrame = CFrame.new(0, 0, 0.55) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)),
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
        Name = "Hat",
        Weld = "Head",
        MeshID = "rbxassetid://73083430479187",
        TextureID = "rbxassetid://104381302798685",
        CFrame = CFrame.new(-0.013, 0.1, -0.005, 1, 0, 0, 0, 1, 0, 0, 0, 1),
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
	},
	{
        Class = "AnimID",
        Name = "Griddy",
        ID = "rbxassetid://75586690784894",
        ReqPlaceID = 93978595733734
    },
	{
		Class = "AnimID",
		Name = "Rampage",
		ID = "rbxassetid://79155929355612",
		ReqPlaceID = 93978595733734
	},
	{
		Class = "AnimR6",
		Name = "GriddyDump",
		URL = "https://raw.githubusercontent.com/mewix1337/DxBreak/refs/heads/violence-district/Griddy.txt",
		ReqPlaceID = 0
	},
	{
		Class = "AnimR6",
		Name = "RampageDump",
		URL = "https://raw.githubusercontent.com/mewix1337/DxBreak/refs/heads/violence-district/Rampage.txt",
		ReqPlaceID = 0
	}
}

-- ============================================================
-- HTTP HELPER
-- ============================================================
local function fetch(url)
    local ok, res = pcall(function()
        return http.request({
            Url     = url,
            Method  = "GET",
            Headers = { ["User-Agent"] = UA }
        })
    end)
    if ok and res and res.StatusCode == 200 then
        return res.Body
    end
    return nil
end

local function loadModule(url)
    local body = fetch(url)
    if not body then return nil end
    local fn, err = loadstring(body)
    if not fn then
        warn("XMS || Loadstring error: " .. tostring(err))
        return nil
    end
    local ok, result = pcall(fn)
    if not ok then
        warn("XMS || Module exec error: " .. tostring(result))
        return nil
    end
    return result
end

-- ============================================================
-- 1. LOAD MIxConfig (Meta Info + Config)
-- ============================================================
local miXconf = loadModule(BASE .. "ximeax/MIxConfig")
if not miXconf then
    warn("XMS | Meta Info + Config not answer, please try later!")
    return
end

print(miXconf.project_name .. " | Loading... | " .. miXconf.project_vers)

-- ============================================================
-- 2. LOAD LOGIC
-- ============================================================
local Logic = loadModule(BASE .. "ximeax/logic")
if not Logic then
    miXconf:logic_down()
    return
end

-- ============================================================
-- 3. LOAD MODULES (Security, Helpers, ModuleSystem)
-- ============================================================
local Modules = loadModule(BASE .. "ximeax/module")
if not Modules then
    miXconf:md_down()
    -- не критично, продолжаем без модулей
    Modules = {}
end

-- ============================================================
-- 4. INIT LOGIC
-- ============================================================
local activeAutoRespawns = {}
local ActiveAnimations   = {}
local LoadedModules      = {}
local DAMode             = "once"
local Aliases            = {}
local Groups             = {}

Logic.Init({
    Library        = Library,
    ActiveAnims    = ActiveAnimations,
    ActiveRespawns = activeAutoRespawns,
    CurrentMode    = DAMode,
    LoadedModules  = LoadedModules,
    ConfigPath     = "xilmess/xms/xSave/",
    RecordApply    = getgenv().XMS_RecordApply or nil,
})

-- ============================================================
-- 5. DAMODE
-- ============================================================
local function SetDAMode(val)
    local v = val:lower():gsub("%s+", "")
    if v == "1" or v == "once" then
        DAMode = "once"; print("XMS || DAMode = once")
    elseif v == "2" or v == "true" then
        DAMode = "true"; print("XMS || DAMode = true")
    elseif v == "reset" or v == "off" then
        DAMode = "once"; print("XMS || DAMode = off")
    else
        warn("XMS || Unknown DAMode: " .. val)
    end
end

-- ============================================================
-- 6. ALIASES & GROUPS
-- ============================================================
local function SetAlias(short, target)
    Aliases[short:lower()] = target:lower()
    print("XMS || Alias: '" .. short .. "' → '" .. target .. "'")
end

local function ResolveAlias(name)
    return Aliases[name:lower()] or name
end

local function SetGroup(groupName, items)
    Groups[groupName:lower()] = items
    print("XMS || Group: '" .. groupName .. "' = " .. table.concat(items, ", "))
end

local function ResolveGroup(name)
    return Groups[name:lower()] or nil
end

-- ============================================================
-- 7. MAIN HANDLER
-- ============================================================
local function MainHandler(name, mode, key)
    if not name then return end
    local raw = tostring(name)
    local n   = ResolveAlias(raw:lower())
    local m   = tostring(mode or DAMode):lower()

    -- Group resolve
    local group = ResolveGroup(n)
    if group then
        for _, itemName in ipairs(group) do MainHandler(itemName, mode) end
        return
    end

    -- DAMode
    local daVal = raw:match("^DAMode%s*=%s*(.+)$")
    if daVal then SetDAMode(daVal); return end

    -- Alias
    local aShort, aTarget = raw:match("^alias%s*=%s*([^,]+),%s*(.+)$")
    if aShort then
        SetAlias(aShort:match("^%s*(.-)%s*$"), aTarget:match("^%s*(.-)%s*$"))
        return
    end

    -- Group set
    local gName, gItems = raw:match("^group%s*=%s*([^,]+),(.+)$")
    if gName then
        local items = {}
        for item in gItems:gmatch("[^,]+") do
            table.insert(items, item:match("^%s*(.-)%s*$"))
        end
        SetGroup(gName:match("^%s*(.-)%s*$"), items)
        return
    end

    -- CMD
    if n == "cmd" then
        local text = Logic.BuildCMD(
            function() return miXconf.project_vers end,
            miXconf.project_catalog,
            miXconf.project_discord
        )
        setclipboard(text)
        print("XMS || CMD copied")
        return
    end

    -- Clear
    if m == "clear" then Logic.DoClear(n); return end

    -- Search in Library
    for _, d in pairs(Library) do
        if d.Name:lower() == n then
            if key and key ~= "" then
                game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
                    if not gpe and input.KeyCode == Enum.KeyCode[key:upper()] then
                        Logic.Apply(d)
                    end
                end)
            else
                Logic.Apply(d)
            end
            if m == "loop" or m == "true" or m == "spawn" then
                activeAutoRespawns[n] = d
            end
            return
        end
    end

    warn("XMS || Item '" .. name .. "' not found")
end

-- ============================================================
-- 8. RESPAWN
-- ============================================================
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    if DAMode == "true" then
        for _, d in pairs(activeAutoRespawns) do
            Logic.Apply(d)
        end
    end
end)

-- ============================================================
-- 9. EXPOSE
-- ============================================================
getgenv().xms = function(...) return MainHandler(...) end
setmetatable(_G, { __call = function(_, ...) return MainHandler(...) end })

print(miXconf.project_name .. " || Loaded ! | " .. miXconf.project_vers)