-- xCMD | Logic Module
-- Returns: Apply, DoClear, BuildCMD
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local lp          = Players.LocalPlayer

local Logic = {}

local _Library        = {}
local _ActiveAnims    = {}
local _ActiveRespawns = {}
local _CurrentMode    = "once"
local _LoadedModules  = {}
local _ConfigPath     = "xELO LLC/xCMD/Configs"
local _RecordApply    = nil

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

-- ============================================================
-- DOCLEAR
-- ============================================================
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
        local savedBody = LoadConfig("PlayerBody")
        if savedBody then
            for partName, meshId in pairs(savedBody) do
                if meshId and meshId ~= "" then
                    local m = Instance.new("CharacterMesh", char)
                    m.BodyPart = Enum.BodyPart[partName]; m.MeshId = meshId
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
        if v.Name:lower() == "g_item_"..n or (n == "all" and v.Name:find("G_Item_")) then v:Destroy() end
    end
end

-- ============================================================
-- APPLY
-- ============================================================
function Logic.Apply(data, sandbox)
    local char = lp.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local lowName   = data.Name:lower()
    local textureId = data.TextureID or data.Texture or ""

    -- Backups
    if data.Class == "Outfit" and not isfile(_ConfigPath.."PlayerOutfit.json") then
        local s, p = char:FindFirstChildOfClass("Shirt"), char:FindFirstChildOfClass("Pants")
        SaveConfig("PlayerOutfit", { Shirt = s and s.ShirtTemplate or "", Pants = p and p.PantsTemplate or "" })
    elseif data.Class == "Head" and not isfile(_ConfigPath.."PlayerHead.json") then
        local h = char:FindFirstChild("Head")
        local m = h and h:FindFirstChildOfClass("SpecialMesh")
        local f = h and h:FindFirstChild("face")
        SaveConfig("PlayerHead", {
            MeshId = m and m.MeshId or "", TextureId = m and m.TextureId or "",
            ScaleX = m and m.Scale.X or 1.25, ScaleY = m and m.Scale.Y or 1.25, ScaleZ = m and m.Scale.Z or 1.25,
            FaceID = f and f.Texture or "rbxasset://textures/face.png"
        })
    elseif data.Class == "Body" and not isfile(_ConfigPath.."PlayerBody.json") then
        local bodyData = { Torso="", LeftArm="", RightArm="", LeftLeg="", RightLeg="" }
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("CharacterMesh") then bodyData[v.BodyPart.Name] = v.MeshId end
        end
        SaveConfig("PlayerBody", bodyData)
    end

    if data.Class == "Outfit" then
        local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
        s.ShirtTemplate = data.ShirtID
        local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
        p.PantsTemplate = data.PantsID

    elseif data.Class == "Head" then
        Logic.DoClear("head")
        local h = char:WaitForChild("Head", 5)
        if h then
            if h:FindFirstChild("face") then h.face.Transparency = 1 end
            local m = h:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", h)
            m.Name = "G_Item_"..lowName; m.MeshId = data.MeshID; m.TextureId = textureId; m.Scale = data.Scale
        end

    elseif data.Class == "Body" then
        Logic.DoClear("body")
        for _, pN in pairs({"Torso","LeftArm","RightArm","LeftLeg","RightLeg"}) do
            if data[pN] then
                local m = Instance.new("CharacterMesh", char)
                m.BodyPart = Enum.BodyPart[pN]; m.MeshId = data[pN]:match("%d+")
            end
        end


    elseif data.Class == "Accessory" then
     Logic.DoClear(lowName)
      local weldName   = data.Weld or "Head"
      local weldTarget = char:FindFirstChild(weldName)
    
       if not weldTarget then
           weldTarget = char:FindFirstChild("Torso") or char:FindFirstChild("Head")
           warn("xCMD || Target " .. weldName .. " not found, defaulting to " .. (weldTarget and weldTarget.Name or "None"))
       end
       
      if weldTarget then
          local part = Instance.new("Part")
          part.Name        = "G_Item_"..lowName
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
        w.Name  = "xCMD_Weld"
        w.Part0 = weldTarget
        w.Part1 = part

        w.C1    = data.CFrame or CFrame.new()
        
        w.Parent = part
        part.Parent = char
    else    
        warn("xCMD || Critical: No weld target found for " .. data.Name)
    end

    elseif data.Class == "Face" then
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

-- ============================================================
-- BUILDCMD
-- ============================================================
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
                '|   js("' .. item.Name .. '")')
        end
    end

    local function printWithSubClass(items, indent)
        local noSub     = {}
        local subMap    = {}
        local subOrder  = {} -- preserves insertion order
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

    if byClass["Body"] or byClass["Head"] then
        table.insert(lines, "  [ Character ]")
        if byClass["Head"] then
            table.insert(lines, "   [ Head ]")
            printWithSubClass(byClass["Head"], "    ")
        end
        if byClass["Body"] then
            table.insert(lines, "   [ Body ]")
            printWithSubClass(byClass["Body"], "    ")
        end
        table.insert(lines, "")
    end

    if byClass["Outfit"] then
        table.insert(lines, "  [ Outfit ]")
        printWithSubClass(byClass["Outfit"], "    ")
        table.insert(lines, "")
    end

    local printed = { Accessory=true, Body=true, Head=true, Outfit=true }
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
    table.insert(lines, '    js("name")          - apply item')
    table.insert(lines, '    js("name", "clear") - clear item')
    table.insert(lines, '    js("all",  "clear") - clear all')
    table.insert(lines, "")
    if catalog then
        table.insert(lines, "    If you need to see all items with photos check our catalog")
        table.insert(lines, "    " .. catalog)
    end
    if discord then table.insert(lines, "    Discord || " .. discord) end
    table.insert(lines, "--]]")

    return table.concat(lines, "\n")
end

-- ============================================================
-- START (called from loader)
-- ============================================================
function Logic.Start(Library, miXconf, ModuleSystem, UA, BASE)
    local function req(url)
        local ok, r = pcall(function()
            return http.request({ Url=url, Method="GET", Headers={["User-Agent"]=UA} })
        end)
        if ok and r and r.StatusCode == 200 then return r.Body end
        return nil
    end

    local function loadMod(url)
        local body = req(url); if not body then return nil end
        local fn, err = loadstring(body)
        if not fn then warn("xCMD || "..tostring(err)); return nil end
        local ok, r = pcall(fn); if not ok then warn("xCMD || "..tostring(r)); return nil end
        return r
    end

    -- Security + Helpers
    local Security = loadMod(BASE .. "static/cmd/md/security") or {
        IsVerified=function()return false end, ValidateModule=function()end,
        RegisterCallsyntax=function()return true end, UnregisterCallsyntax=function()end,
        CheckVersion=function()return true end, CreateSandbox=function()return{}end,
        RegisterModule=function()end, UnregisterModule=function()end,
    }
    local Helpers = loadMod(BASE .. "static/cmd/md/helpers") or {}

    -- Shared state
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
        ConfigPath     = "hux9z/JS/x³²/xSave/",
        RecordApply    = getgenv().xCMD_RecordApply or nil,
    })

    if ModuleSystem and ModuleSystem.Init then
        ModuleSystem.Init({
            Security=Security, Helpers=Helpers, LoadedModules=LoadedModules,
            DoClear=function(...) Logic.DoClear(...) end,
            GetVersion=function() return miXconf.project_vers end,
            Apply=function(...) Logic.Apply(...) end,
            MODULES_PATH="hux9z/JS/32/modules/", DB_PATH="hux9z/JS/32/db/",
        })
        local modList = loadMod(BASE .. "hux9z/jsx32/modules")
        if modList then
            for _, url in ipairs(modList) do task.spawn(function() ModuleSystem.Load(url) end) end
        end
    end

    -- DAMode
    local function SetDAMode(val)
        local v = val:lower():gsub("%s+","")
        if v=="1" or v=="once" then DAMode="once"; print("xCMD || DAMode = once")
        elseif v=="2" or v=="true" then DAMode="true"; print("xCMD || DAMode = true")
        elseif v=="reset" or v=="off" then DAMode="once"; print("xCMD || DAMode = off")
        else warn("xCMD || Unknown DAMode: "..val) end
    end

    -- Aliases + Groups
    local function SetAlias(s,t) Aliases[s:lower()]=t:lower(); print("xCMD || Alias: '"..s.."' → '"..t.."'") end
    local function ResolveAlias(n) return Aliases[n:lower()] or n end
    local function SetGroup(g,i) Groups[g:lower()]=i end
    local function ResolveGroup(n) return Groups[n:lower()] or nil end

    -- MainHandler
    local function MainHandler(name, mode, key)
        if not name then return end
        local raw = tostring(name)
        local n   = ResolveAlias(raw:lower())
        local m   = tostring(mode or DAMode):lower()

        local group = ResolveGroup(n)
        if group then for _, i in ipairs(group) do MainHandler(i, mode) end; return end

        local daVal = raw:match("^DAMode%s*=%s*(.+)$"); if daVal then SetDAMode(daVal); return end
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
            print("xCMD || CMD copied"); return
        end

        if m == "clear" then Logic.DoClear(n); return end

        for _, d in pairs(Library) do
            if d.Name:lower() == n then
                if d.ReqPlaceID and d.ReqPlaceID ~= 0 and tonumber(d.ReqPlaceID) ~= game.PlaceId then
                    warn("xCMD || Item '"..d.Name.."' not available"); return
                end
                if key and key ~= "" then
                    game:GetService("UserInputService").InputBegan:Connect(function(i,gp)
                        if not gp and i.KeyCode == Enum.KeyCode[key:upper()] then Logic.Apply(d) end
                    end)
                else Logic.Apply(d) end
                if m=="loop" or m=="true" or m=="spawn" then activeAutoRespawns[n]=d end
                return
            end
        end

        for _, mod in pairs(LoadedModules) do
            for _, d in pairs(mod.library or {}) do
                if d.Name:lower() == n then
                    Logic.Apply(d, mod.sandbox)
                    if m=="loop" or m=="true" or m=="spawn" then activeAutoRespawns[n]=d end
                    return
                end
            end
        end

        warn("xCMD || Item '"..name.."' not found")
    end

    -- Respawn
    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        if DAMode == "true" then
            for _, d in pairs(activeAutoRespawns) do Logic.Apply(d) end
        end
    end)

    -- Expose
    getgenv().xc = function(...) return MainHandler(...) end
    setmetatable(_G, { __call = function(_, ...) return MainHandler(...) end })
end

return Logic