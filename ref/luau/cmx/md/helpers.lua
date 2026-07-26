--[ luau/cmd/md/helpers.lua ]
local Helpers = {}

local lp = game:GetService("Players").LocalPlayer

function Helpers.Inject(sandbox, DoClearFn)
    local function getChar()
        return lp.Character
    end
    sandbox.changeoutfit = function(data)
        if not data then return end
        local char = getChar()
        if not char then return end
        if data.shirt and data.shirt ~= "" then
            local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
            s.ShirtTemplate = tostring(data.shirt)
        end
        if data.pants and data.pants ~= "" then
            local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
            p.PantsTemplate = tostring(data.pants)
        end
    end

    -- [ changehead ]
    -- changehead({ mesh = "rbxassetid://123", texture = "rbxassetid://456", scale = {1,1,1} })
    sandbox.changehead = function(data)
        if not data then return end
        local char = getChar()
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local m = head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", head)
        if data.mesh    then m.MeshId    = tostring(data.mesh)    end
        if data.texture then m.TextureId = tostring(data.texture) end
        if data.scale   then
            m.Scale = Vector3.new(
                tonumber(data.scale[1]) or 1,
                tonumber(data.scale[2]) or 1,
                tonumber(data.scale[3]) or 1
            )
        end
        if data.hidefce then
            local face = head:FindFirstChild("face")
            if face then face.Transparency = data.hidefce and 1 or 0 end
        end
    end

    -- [ changebody ]
    -- changebody({ torso = "id", leftarm = "id", rightarm = "id", leftleg = "id", rightleg = "id" })
    sandbox.changebody = function(data)
        if not data then return end
        local char = getChar()
        if not char then return end
        -- Удаляем старые
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("CharacterMesh") then v:Destroy() end
        end
        local map = {
            torso    = "Torso",
            leftarm  = "LeftArm",
            rightarm = "RightArm",
            leftleg  = "LeftLeg",
            rightleg = "RightLeg",
        }
        for key, partName in pairs(map) do
            local id = data[key]
            if id and id ~= "" then
                local m = Instance.new("CharacterMesh", char)
                m.BodyPart = Enum.BodyPart[partName]
                m.MeshId   = tostring(id):match("%d+") or tostring(id)
            end
        end
    end

    -- [ addaccessory ]
    -- addaccessory({ name = "myhat", mesh = "id", texture = "id", weld = "Head", pos = {0,0,0}, rt = {0,0,0} })
    sandbox.addaccessory = function(data)
        if not data then return end
        local char = getChar()
        if not char then return end

        local name    = tostring(data.name or "mod_accessory")
        local weldTo  = data.weld or "Head"
        local pos     = data.pos or {0, 0, 0}
        local rt      = data.rt  or {0, 0, 0}

        -- Удаляем старый если есть
        local old = char:FindFirstChild("G_Item_" .. name:lower())
        if old then old:Destroy() end

        local part = Instance.new("Part", char)
        part.Name       = "G_Item_" .. name:lower()
        part.Size       = Vector3.new(1, 1, 1)
        part.CanCollide = false
        part.Anchored   = false

        local m = Instance.new("SpecialMesh", part)
        m.MeshId    = tostring(data.mesh    or "")
        m.TextureId = tostring(data.texture or "")

        local weldPart = char:FindFirstChild(weldTo)
        if weldPart then
            local w = Instance.new("Weld", part)
            w.Part0 = part
            w.Part1 = weldPart
            w.C0    = CFrame.new(
                tonumber(pos[1]) or 0,
                tonumber(pos[2]) or 0,
                tonumber(pos[3]) or 0
            ) * CFrame.fromEulerAnglesXYZ(
                math.rad(tonumber(rt[1]) or 0),
                math.rad(tonumber(rt[2]) or 0),
                math.rad(tonumber(rt[3]) or 0)
            )
        end
    end

    -- [ changeanimation ] — только R15, меняет пак анимаций через Animate
    -- changeanimation({ idle = "id", walk = "id", run = "id", jump = "id", fall = "id", climb = "id", swim = "id" })
    sandbox.changeanimation = function(data)
        if not data then return end
        local char = getChar()
        if not char then return end
        local animate = char:FindFirstChild("Animate")
        if not animate then return end

        local map = {
            idle  = {"idle",  "Animation1"},
            walk  = {"walk",  "WalkAnim"},
            run   = {"run",   "RunAnim"},
            jump  = {"jump",  "JumpAnim"},
            fall  = {"fall",  "FallAnim"},
            climb = {"climb", "ClimbAnim"},
            swim  = {"swim",  "Swim"},
        }

        for key, path in pairs(map) do
            local id = data[key]
            if id and id ~= "" then
                local folder = animate:FindFirstChild(path[1])
                if folder then
                    local anim = folder:FindFirstChild(path[2])
                    if anim and anim:IsA("Animation") then
                        anim.AnimationId = tostring(id)
                    end
                end
            end
        end

        -- Перезапускаем Animate чтобы применились
        animate.Disabled = true
        task.wait(0.1)
        animate.Disabled = false
    end

    -- [ clear ]
    -- clear("head") / clear("all")
    sandbox.clear = function(target)
        if DoClearFn then
            DoClearFn(tostring(target or "all"))
        end
    end

    -- [ getchar ] — безопасный доступ к персонажу
    sandbox.getchar = function()
        return getChar()
    end

    -- [ getplayer ] — только LocalPlayer базовые данные
    sandbox.getplayer = function()
        return {
            name   = lp.Name,
            userid = lp.UserId,
        }
    end

    return sandbox
end

return Helpers