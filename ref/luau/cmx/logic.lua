-- [ ref/luau/cmx/logic.lua ]
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer
local Logic = {}
local _Library        = {}
local _ActiveAnims    = {}
local _ActiveRespawns = {}
local _CurrentMode    = "once"
local _LoadedModules  = {}
local _ConfigPath     = "iME/CMX/Configs"
local _RecordApply    = nil

local function HttpGet(url)
    if not url or url == "" then return nil end

    local ok, result = pcall(function()
        if game and typeof(game.HttpGet) == "function" then
            return game:HttpGet(url)
        end

        local httpService = game:GetService("HttpService")
        return httpService:GetAsync(url)
    end)

    if ok then
        return result
    end

    return nil
end

function Logic.Init(ctx)
    _Library        = ctx.Library        or {}
    _ActiveAnims    = ctx.ActiveAnims    or {}
    _ActiveRespawns = ctx.ActiveRespawns or {}
    _CurrentMode    = ctx.CurrentMode    or "once"
    _LoadedModules  = ctx.LoadedModules  or {}
    _ConfigPath     = ctx.ConfigPath     or _ConfigPath
    _RecordApply    = ctx.RecordApply    or nil
end

local function SaveConfig(name, data)
    writefile(_ConfigPath .. name .. ".json", HttpService:JSONEncode(data))
end

local function LoadConfig(name)
    local path = _ConfigPath .. name .. ".json"
    if isfile(path) then
        local ok, r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        return ok and r or nil
    end
    return nil
end

local function IsPlaceAllowed(item)
    if not item.ReqPlaceID or item.ReqPlaceID == 0 or item.ReqPlaceID == "" then return true end
    return tonumber(item.ReqPlaceID) == game.PlaceId
end

local function GetEffectiveClass(item)
    local class = item.Class or ""
    local subClass = tostring(item.SubClass or ""):match("^%s*(.-)%s*$")

    if class == "Character" and subClass == "Body" then
        return "Body"
    end

    return class
end


local R15PartNames = {
    "Head",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function IsIndividualR15Definition(definition)
    if type(definition) ~= "table" then return false end
    for _, partName in ipairs(R15PartNames) do
        if definition[partName] then return true end
    end
    return false
end

local function ToAssetId(value)
    local id = tostring(value or "")
    if id == "" then return "" end
    if id:find("rbxassetid://", 1, true) then return id end
    local number = id:match("%d+")
    return number and "rbxassetid://" .. number or id
end

local function ApplyIndividualR15Parts(char, definition)
    for _, partName in ipairs(R15PartNames) do
        local entry = definition[partName]
        local meshId = type(entry) == "table" and (entry.MeshID or entry.ID) or entry
        local target = char:FindFirstChild(partName)

        if target and meshId and tostring(meshId) ~= "" then
            for _, child in ipairs(target:GetChildren()) do
                if child:IsA("SpecialMesh") and child:GetAttribute("CMXR15Body") then
                    child:Destroy()
                end
            end

            local mesh = Instance.new("SpecialMesh")
            mesh.Name = partName
            mesh:SetAttribute("CMXR15Body", true)
            mesh:SetAttribute("CMXItemName", itemName)
            mesh.MeshId = ToAssetId(meshId)
            if type(entry) == "table" then
                mesh.TextureId = ToAssetId(entry.TextureID or entry.Texture)
                mesh.Scale = entry.Scale or Vector3.new(1, 1, 1)
            end
            mesh.Parent = target
        elseif entry then
            warn("CMX || R15 part '" .. partName .. "' was not found")
        end
    end
end

function Logic.DoClear(target)
    local char = lp.Character
    if not char then return end
    local n = tostring(target):lower()

    if n == "all" or _ActiveAnims[n] then
        if n == "all" then
            for _, c in pairs(_ActiveAnims) do
                if c.Disconnect then c:Disconnect() elseif c.Stop then c:Stop() end
            end
            _ActiveAnims = {}; _ActiveRespawns = {}
        else
            local a = _ActiveAnims[n]
            if a then
                if a.Disconnect then a:Disconnect() elseif a.Stop then a:Stop() end
                _ActiveAnims[n] = nil; _ActiveRespawns[n] = nil
            end
        end
        if char:FindFirstChild("Animate") then char.Animate.Disabled = false end
    end

    if n == "all" or n == "head" then
        local head = char:FindFirstChild("Head")
        if head then
            for _, v in pairs(head:GetChildren()) do
                if v.Name:find("G_Item_") then v:Destroy() end
            end
            local saved = LoadConfig("PlayerHead")
            if saved then
                local m = head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", head)
                m.MeshId = saved.MeshId; m.TextureId = saved.TextureId
                m.Scale  = Vector3.new(saved.ScaleX, saved.ScaleY, saved.ScaleZ)
                if head:FindFirstChild("face") then
                    head.face.Texture = saved.FaceID; head.face.Transparency = 0
                end
            else
                local m = head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", head)
                m.MeshType = Enum.MeshType.Head; m.MeshId = ""; m.TextureId = ""
                m.Scale    = Vector3.new(1.25, 1.25, 1.25)
                local face = head:FindFirstChild("face")
                if face then face.Transparency = 0; if face.Texture == "" then face.Texture = "rbxasset://textures/face.png" end end
            end
        end
    end

    if n == "all" or n == "body" then
        for _, v in pairs(char:GetChildren()) do if v:IsA("CharacterMesh") then v:Destroy() end end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("SpecialMesh") and (v:GetAttribute("CMXR15Body") or v.Name == "R15Mesh" or v.Name == "CMX_R15Mesh") then
                v:Destroy()
        end
        local savedBody = LoadConfig("PlayerBody")
        if savedBody then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if savedBody.RigType == "R15" and humanoid then
                local ok, description = pcall(function() return humanoid:GetAppliedDescription() end)
                if ok and description then
                    for _, partName in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                        if savedBody[partName] then description[partName] = savedBody[partName] end
                    end
                    pcall(function() humanoid:ApplyDescription(description) end)
                end
            else
                for partName, meshId in pairs(savedBody) do
                    if Enum.BodyPart[partName] and meshId and meshId ~= "" then
                        local m = Instance.new("CharacterMesh", char)
                        m.BodyPart = Enum.BodyPart[partName]; m.MeshId = meshId
                    end
                end
            end
        end
    end

    local isOutfit = (n == "all" or n == "outfit")
    if not isOutfit then
        for _, i in pairs(_Library) do
            if i.Name:lower() == n and i.Class == "Outfit" then isOutfit = true; break end
        end
    end
    if isOutfit then
        local saved = LoadConfig("PlayerOutfit")
        if saved then
            local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
            s.ShirtTemplate = saved.Shirt
            local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
            p.PantsTemplate = saved.Pants
        end
    end

    for _, v in pairs(char:GetDescendants()) do
        local isCMXItem = v:GetAttribute("CMXItemName") ~= nil
        if (isCMXItem and (n == "all" or v:GetAttribute("CMXItemName") == n))
            or v.Name:lower() == "g_item_"..n
            or (n == "all" and v.Name:find("G_Item_")) then
            v:Destroy()
        end
    end
end

function Logic.Apply(data, sandbox)
    local char = lp and lp.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local humanoid  = char:FindFirstChildOfClass("Humanoid")
    local itemClass = GetEffectiveClass(data)
    local useIndividualR15Parts = itemClass == "Body"
        and humanoid.RigType == Enum.HumanoidRigType.R15
        and IsIndividualR15Definition(data.R15)

    if itemClass == "Body" and (data.R6 or data.R15) then
        local rigKey = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
        local rigData = data[rigKey]
        if type(rigData) ~= "table" then
            warn("CMX || Body '" .. tostring(data.Name) .. "' has no " .. rigKey .. " definition")
            return
        end

        local resolved = {}
        for k, v in pairs(data) do resolved[k] = v end
        for k, v in pairs(rigData) do resolved[k] = v end
        resolved.R6, resolved.R15 = nil, nil
        data = resolved
    end
    local lowName   = data.Name:lower()
    local textureId = data.TextureID or data.Texture or ""
    local isHeadItem = itemClass == "Head" or itemClass == "Character"

    if itemClass == "Outfit" and not isfile(_ConfigPath.."PlayerOutfit.json") then
        local s, p = char:FindFirstChildOfClass("Shirt"), char:FindFirstChildOfClass("Pants")
        SaveConfig("PlayerOutfit", { Shirt = s and s.ShirtTemplate or "", Pants = p and p.PantsTemplate or "" })
    elseif itemClass == "Head" and not isfile(_ConfigPath.."PlayerHead.json") then
        local h = char:FindFirstChild("Head")
        local m = h and h:FindFirstChildOfClass("SpecialMesh")
        local f = h and h:FindFirstChild("face")
        SaveConfig("PlayerHead", {
            MeshId = m and m.MeshId or "", TextureId = m and m.TextureId or "",
            ScaleX = m and m.Scale.X or 1.25, ScaleY = m and m.Scale.Y or 1.25, ScaleZ = m and m.Scale.Z or 1.25,
            FaceID = f and f.Texture or "rbxasset://textures/face.png"
        })
    elseif itemClass == "Body" and not isfile(_ConfigPath.."PlayerBody.json") then
        local bodyData
        if humanoid.RigType == Enum.HumanoidRigType.R15 then
            local description = humanoid:GetAppliedDescription()
            bodyData = {
                RigType = "R15", Head = description.Head, Torso = description.Torso,
                LeftArm = description.LeftArm, RightArm = description.RightArm,
                LeftLeg = description.LeftLeg, RightLeg = description.RightLeg,
            }
        else
            bodyData = { Torso="", LeftArm="", RightArm="", LeftLeg="", RightLeg="" }
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("CharacterMesh") then bodyData[v.BodyPart.Name] = v.MeshId end
            end
        end
        SaveConfig("PlayerBody", bodyData)
    end

    if itemClass == "Outfit" then
        local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
        s.ShirtTemplate = data.ShirtID
        local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
        p.PantsTemplate = data.PantsID

    elseif isHeadItem then
        Logic.DoClear("head")
        local h = char:WaitForChild("Head", 5)
        if h then
            if h:FindFirstChild("face") then h.face.Transparency = 1 end
            local m = h:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", h)
            m.Name = "Head"; m:SetAttribute("CMXItemName", lowName)
            m.MeshId = data.MeshID; m.TextureId = textureId; m.Scale = data.Scale or Vector3.new(1, 1, 1)
        end

    elseif itemClass == "Body" then
        Logic.DoClear("body")
        if humanoid.RigType == Enum.HumanoidRigType.R15 then
            if useIndividualR15Parts then
                ApplyIndividualR15Parts(char, data)
            else
                local ok, description = pcall(function()
                    return humanoid:GetAppliedDescription()
                end)
                if not ok or not description then
                    warn("CMX || Couldn't read the R15 humanoid description for '" .. data.Name .. "'")
                    return
                end

                for _, partName in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                    if data[partName] then
                        description[partName] = tostring(data[partName]):match("%d+") or "0"
                    end
                end
                local applied, err = pcall(function() humanoid:ApplyDescription(description) end)
                if not applied then warn("CMX || Couldn't apply R15 body '" .. data.Name .. "': " .. tostring(err)) end
            end
        else
            for _, pN in ipairs({"Torso","LeftArm","RightArm","LeftLeg","RightLeg"}) do
                if data[pN] then
                    local m = Instance.new("CharacterMesh", char)
                    m.Name = pN
                    m:SetAttribute("CMXItemName", lowName)
                    m.BodyPart = Enum.BodyPart[pN]; m.MeshId = data[pN]:match("%d+")
                end
            end
        end


    elseif itemClass == "Accessory" then
     Logic.DoClear(lowName)
      local weldName   = data.Weld or "Head"
      local weldTarget = char:FindFirstChild(weldName)
    
       if not weldTarget then
           weldTarget = char:FindFirstChild("Torso") or char:FindFirstChild("Head")
           warn("CMX || Target " .. weldName .. " not found, defaulting to " .. (weldTarget and weldTarget.Name or "None"))
       end
       
      if weldTarget then
          local part = Instance.new("Part")
          part.Name        = lowName
          part:SetAttribute("CMXItemName", lowName)
          part.Size        = Vector3.new(0.5, 0.5, 0.5)
          part.CanCollide  = false
          part.Massless    = true
          part.Transparency = 0
        
          local m = Instance.new("SpecialMesh", part)
           m.MeshId    = data.MeshID and (tostring(data.MeshID):find("rbxassetid://") and data.MeshID or "rbxassetid://"..tostring(data.MeshID):match("%d+")) or ""
           m.TextureId = textureId ~= "" and (tostring(textureId):find("rbxassetid://") and textureId or "rbxassetid://"..tostring(textureId):match("%d+")) or ""
          if typeof(data.Scale) == "number" then
            m.Scale = Vector3.new(data.Scale, data.Scale, data.Scale)
          else
            m.Scale = data.Scale or Vector3.new(1, 1, 1)
        end
        
        local w = Instance.new("Weld")
        w.Name  = "CMX_Weld"
        w.Part0 = weldTarget
        w.Part1 = part

        w.C1    = data.CFrame or CFrame.new()
        
        w.Parent = part
        part.Parent = char
    else    
        warn("CMX || Critical: No weld target found for " .. data.Name)
    end

    elseif itemClass == "Face" then
        local h = char:FindFirstChild("Head")
        if h and h:FindFirstChild("face") then h.face.Texture = data.ID end

    elseif sandbox then
        if data.FunctionURL and data.FunctionURL ~= "" then
            local ok, code = pcall(game.HttpGet, game, data.FunctionURL)
            if ok then local fn = load(code, data.Name, "t", sandbox); if fn then pcall(fn) end end
        elseif data.FunctionCode and data.FunctionCode ~= "" then
            local fn = load(data.FunctionCode, data.Name, "t", sandbox); if fn then pcall(fn) end
        end
    end

    if _RecordApply then _RecordApply(data.Name) end
end

function Logic.BuildCMD(getVersion, catalog, discord, projectName)
    local version = getVersion and getVersion() or "unknown"
    local name    = projectName 
    local lines   = {}

    table.insert(lines, "--[[")
    table.insert(lines, "    " .. name .. " List || " .. version)
    table.insert(lines, "")
    table.insert(lines, " [ Built-in ]")

    local byClass = {}
    for _, item in pairs(_Library) do
        if IsPlaceAllowed(item) then
            local cls = item.Class or "-"
            if not byClass[cls] then byClass[cls] = {} end
            table.insert(byClass[cls], item)
        end
    end

    local function printItems(items, indent)
        for _, item in pairs(items) do
            table.insert(lines, indent .. item.Name ..
                string.rep(" ", math.max(1, 22 - #item.Name)) ..
                '|   cx("' .. item.Name .. '")')
        end
    end

    local function printWithSubClass(items, indent)
        local noSub     = {}
        local subMap    = {}
        local subOrder  = {}
        for _, item in ipairs(items) do
            local sub = item.SubClass
            if sub and sub:match("^%s*(.-)%s*$") ~= "" then
                sub = sub:match("^%s*(.-)%s*$")
                if not subMap[sub] then
                    subMap[sub] = {}
                    table.insert(subOrder, sub)
                end
                table.insert(subMap[sub], item)
            else
                table.insert(noSub, item)
            end
        end
        printItems(noSub, indent)
        for _, subName in ipairs(subOrder) do
            table.insert(lines, indent .. "[ " .. subName .. " ]")
            printItems(subMap[subName], indent .. "  ")
        end
    end

    if byClass["Accessory"] then
        table.insert(lines, "  [ Accessory ]")
        printWithSubClass(byClass["Accessory"], "    ")
        table.insert(lines, "")
    end

    if byClass["Character"] or byClass["Head"] then
        table.insert(lines, "  [ Character ]")
        if byClass["Head"] then
            table.insert(lines, "   [ Head ]")
            printWithSubClass(byClass["Head"], "    ")
        end
        if byClass["Character"] then
            printWithSubClass(byClass["Character"], "    ")
        end
        table.insert(lines, "")
    end

    if byClass["Outfit"] then
        table.insert(lines, "  [ Outfit ]")
        printWithSubClass(byClass["Outfit"], "    ")
        table.insert(lines, "")
    end

    local printed = { Accessory=true, Character=true, Head=true, Outfit=true }
    for cls, items in pairs(byClass) do
        if not printed[cls] then
            table.insert(lines, "  [ " .. cls .. " ]")
            printWithSubClass(items, "    ")
            table.insert(lines, "")
        end
    end

    table.insert(lines, "")
    table.insert(lines, "")
    table.insert(lines, "")
    table.insert(lines, "    " .. name .. " Commands")
    table.insert(lines, "")
    table.insert(lines, '    cx("name")          - apply item')
    table.insert(lines, '    cx("name", "clear") - clear item')
    table.insert(lines, '    cx("all",  "clear") - clear all')
    table.insert(lines, '    cx("name", "true"/"2")  - reapply item after respawn')
    table.insert(lines, '    cx("name", "false"/"1") - apply once and disable reapply')
    table.insert(lines, '    cx("name", "reset"/"off") - disable reapply for item')
    table.insert(lines, "")
    if catalog then
        table.insert(lines, "    If you need to see all items with photos check our catalog")
        table.insert(lines, "    " .. catalog)
    end
    if discord then table.insert(lines, "    Discord || " .. discord) end
    table.insert(lines, "--]]")

    return table.concat(lines, "\n")
end


function Logic.Start(Library, miXconf, ModuleSystem, UA, BASE)
    local function req(url)
        local body = HttpGet(url)
        if body and type(body) == "string" then return body end
        return nil
    end

    local function loadMod(url)
        local body = req(url); if not body then return nil end
        local fn, err = loadstring(body)
        if not fn then warn("CMX || "..tostring(err)); return nil end
        local ok, r = pcall(fn); if not ok then warn("CMX || "..tostring(r)); return nil end
        return r
    end

    local Security = loadMod("https://izsfin.github.io/ref/luau/cmx/md/security.lua") or {
        IsVerified=function()return false end, ValidateModule=function()end,
        RegisterCallsyntax=function()return true end, UnregisterCallsyntax=function()end,
        CheckVersion=function()return true end, CreateSandbox=function()return{}end,
        RegisterModule=function()end, UnregisterModule=function()end,
    }
    local Helpers = loadMod("https://izsfin.github.io/ref/luau/cmx/md/helpers.lua") or {}
    local activeAutoRespawns = {}
    local ActiveAnimations   = {}
    local LoadedModules      = {}
    local Aliases            = {}
    local Groups             = {}

    Logic.Init({
        Library        = Library,
        ActiveAnims    = ActiveAnimations,
        ActiveRespawns = activeAutoRespawns,
        CurrentMode    = "once",
        LoadedModules  = LoadedModules,
        ConfigPath     = "iME/CMX/Configs/",
        RecordApply    = getgenv().cx_RecordApply or nil,
    })

    if ModuleSystem and ModuleSystem.Init then
        ModuleSystem.Init({
            Security=Security, Helpers=Helpers, LoadedModules=LoadedModules,
            DoClear=function(...) Logic.DoClear(...) end,
            GetVersion=function() return miXconf.project_vers end,
            Apply=function(...) Logic.Apply(...) end,
            MODULES_PATH="iME/CMX/modules/", DB_PATH="iME/CMX/db/",
        })
        local modList = loadMod("https://izsfin.github.io/ref/luau/cmx/md/modules.lua")
        if modList then
            for _, url in ipairs(modList) do task.spawn(function() ModuleSystem.Load(url) end) end
        end
    end

    local function SetItemDAMode(itemName, mode, data, sandbox)
        local v = tostring(mode or "once"):lower():gsub("%s+", "")
        if v == "true" or v == "2" or v == "true/2" or v == "loop" or v == "spawn" then
            activeAutoRespawns[itemName] = { data = data, sandbox = sandbox }
        elseif v == "false" or v == "1" or v == "false/1" or v == "once" or v == "reset" or v == "off" or v == "reset/off" then
            activeAutoRespawns[itemName] = nil
        else
            warn("CMX || Unknown DAMode for '" .. itemName .. "': " .. tostring(mode))
        end
    end

    local function SetAlias(s,t) Aliases[s:lower()]=t:lower(); print("CMX || Alias: '"..s.."' → '"..t.."'") end
    local function ResolveAlias(n) return Aliases[n:lower()] or n end
    local function SetGroup(g,i) Groups[g:lower()]=i end
    local function ResolveGroup(n) return Groups[n:lower()] or nil end

    local function MainHandler(name, mode, key)
        if not name then return end
        local raw = tostring(name)
        local n   = ResolveAlias(raw:lower())
        local m   = tostring(mode or "once"):lower()

        local group = ResolveGroup(n)
        if group then for _, i in ipairs(group) do MainHandler(i, mode) end; return end

        local aS, aT = raw:match("^alias%s*=%s*([^,]+),%s*(.+)$")
        if aS then SetAlias(aS:match("^%s*(.-)%s*$"), aT:match("^%s*(.-)%s*$")); return end
        local gN, gI = raw:match("^group%s*=%s*([^,]+),(.+)$")
        if gN then
            local items = {}
            for i in gI:gmatch("[^,]+") do table.insert(items, i:match("^%s*(.-)%s*$")) end
            SetGroup(gN:match("^%s*(.-)%s*$"), items); return
        end

        if ModuleSystem then
            local mU = raw:match("^mload%s*=%s*(.+)$"); if mU then ModuleSystem.Load(mU:match("^%s*(.-)%s*$")); return end
            local uN = raw:match("^unload%s*=%s*(.+)$"); if uN then ModuleSystem.Unload(uN:match("^%s*(.-)%s*$")); return end
            local upN = raw:match("^update%s*=%s*(.+)$"); if upN then ModuleSystem.Update(upN:match("^%s*(.-)%s*$")); return end
            local oN = raw:match("^[Oo][Mm]load%s*=%s*(.+)$"); if oN then ModuleSystem.OldLoad(oN:match("^%s*(.-)%s*$")); return end
        end

        if n == "cmd" then
            local modLines = ModuleSystem and ModuleSystem.BuildCMDLines(Security.IsVerified) or {}
            local builtIn  = Logic.BuildCMD(function() return miXconf.project_vers end, miXconf.project_catalog, miXconf.project_discord, miXconf.project_name)
            setclipboard(table.concat(modLines,"\n") .. "\n" .. builtIn)
            print("CMX || CMD copied"); return
        end

        if m == "clear" then
            if n == "all" then
                for itemName in pairs(activeAutoRespawns) do activeAutoRespawns[itemName] = nil end
            else
                activeAutoRespawns[n] = nil
            end
            Logic.DoClear(n)
            return
        end

        for _, d in pairs(Library) do
            if d.Name:lower() == n then
                if d.ReqPlaceID and d.ReqPlaceID ~= 0 and tonumber(d.ReqPlaceID) ~= game.PlaceId then
                    warn("CMX || Item '"..d.Name.."' not available"); return
                end
                if key and key ~= "" then
                    game:GetService("UserInputService").InputBegan:Connect(function(i,gp)
                        if not gp and i.KeyCode == Enum.KeyCode[key:upper()] then Logic.Apply(d) end
                    end)
                else Logic.Apply(d) end
                SetItemDAMode(n, m, d)
                return
            end
        end

        for _, mod in pairs(LoadedModules) do
            for _, d in pairs(mod.library or {}) do
                if d.Name:lower() == n then
                    Logic.Apply(d, mod.sandbox)
                    SetItemDAMode(n, m, d, mod.sandbox)
                    return
                end
            end
        end

        warn("CMX || Item '"..name.."' not found")
    end

    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        for _, entry in pairs(activeAutoRespawns) do
            Logic.Apply(entry.data, entry.sandbox)
        end
    end)

    getgenv().cx = function(...) return MainHandler(...) end
    setmetatable(_G, { __call = function(_, ...) return MainHandler(...) end })
end

return Logic
