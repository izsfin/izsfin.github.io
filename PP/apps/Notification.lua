-- Prototype Phone | Notification.lua
-- xELO LLC / SyntoriMS

local Notification = {}
local SP           = getgenv().PP.StaticPhone
local TweenService = game:GetService("TweenService")

-- Очередь уведомлений
local queue   = {}
local showing = false

local ScreenGui = game:GetService("CoreGui"):FindFirstChild("PrototypePhone")

local function getPhone()
    local sg = game:GetService("CoreGui"):FindFirstChild("PrototypePhone")
    if sg then return sg:FindFirstChild("Phone") end
    return nil
end

local function showNext()
    if showing or #queue == 0 then return end
    showing = true

    local notif = table.remove(queue, 1)
    local phone = getPhone()
    if not phone then
        showing = false
        return
    end

    local island = phone:FindFirstChild("StatusBar") 
        and phone.StatusBar:FindFirstChild("Island")
    if not island then
        showing = false
        return
    end

    local notifLabel = island:FindFirstChild("IslandNotif")
    if not notifLabel then
        showing = false
        return
    end

    -- Расширить остров
    TweenService:Create(island, 
        TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, SP.Layout.IslandHeight),
    }):Play()

    notifLabel.Text    = notif.sender .. ": " .. notif.message
    notifLabel.Visible = true

    task.delay(2, function()
        TweenService:Create(island,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, SP.Layout.IslandWidth, 0, SP.Layout.IslandHeight),
        }):Play()
        task.wait(0.35)
        notifLabel.Visible = false
        notifLabel.Text    = ""
        showing = false
        showNext() -- следующее из очереди
    end)
end

function Notification:Push(sender, message)
    table.insert(queue, { sender = sender, message = message })
    showNext()
end

return Notification