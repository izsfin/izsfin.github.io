-- Prototype Phone | Store.lua
-- xELO LLC / SyntoriMS

local Store = {}
local SP = getgenv().PP.StaticPhone

local function makeLabel(props)
    local l = Instance.new("TextLabel")
    for k, v in pairs(props) do l[k] = v end
    return l
end

function Store:Render(container)
    local frame = Instance.new("Frame")
    frame.Name              = "Store"
    frame.Size              = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3  = SP.Colors.Background
    frame.BorderSizePixel   = 0
    frame.Parent            = container

    -- Иконка
    local icon = Instance.new("ImageLabel")
    icon.Size               = UDim2.new(0, 64, 0, 64)
    icon.Position           = UDim2.new(0.5, -32, 0.4, -48)
    icon.BackgroundTransparency = 1
    icon.Image              = SP.Icons.Store or ""
    icon.ImageColor3        = SP.Colors.TextMuted
    icon.ZIndex             = 2
    icon.Parent             = frame

    makeLabel({
        Size = UDim2.new(1, -32, 0, 24),
        Position = UDim2.new(0, 16, 0.4, 24),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.Text,
        Font = SP.Font.Bold,
        TextSize = 16,
        Text = "Store don't working now",
        ZIndex = 2,
        Parent = frame,
    })

    makeLabel({
        Size = UDim2.new(1, -32, 0, 18),
        Position = UDim2.new(0, 16, 0.4, 52),
        BackgroundTransparency = 1,
        TextColor3 = SP.Colors.TextMuted,
        Font = SP.Font.Regular,
        TextSize = 12,
        Text = "Please, try again later",
        ZIndex = 2,
        Parent = frame,
    })
end

return Store