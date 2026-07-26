-- // Static.lua
return function(Icons, Colors)

    -- Парсим Colors из "R, G, B" строк в Color3
    local function parseColor(str)
        local r, g, b = str:match("(%d+),%s*(%d+),%s*(%d+)")
        return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
    end

    local parsed = {
        print = parseColor(Colors.print),
        warn  = parseColor(Colors.warn),
        error = parseColor(Colors.error),
        urlda = parseColor(Colors.urlda),
    }

    -- Глобалки для DC
    getgenv().DC_ParsedColors = parsed
    getgenv().DC_Icons        = Icons

    return {
        Colors = parsed,
        Icons  = Icons,
    }
end