-- Prototype Phone | SS.lua
-- xELO LLC / SyntoriMS

local SS = {}

SS.API_URL = "https://ppdb.melatoninllc.workers.dev"
SS.SECRET  = "pp_secret_key_melatoninllc"

local HttpService = game:GetService("HttpService")

local function request(method, path, body)
    local ok, res = pcall(http_request, {
        Url     = SS.API_URL .. path,
        Method  = method,
        Headers = {
            ["X-PP-Secret"]  = SS.SECRET,
            ["Content-Type"] = "application/json",
        },
        Body = body and HttpService:JSONEncode(body) or nil,
    })
    if not ok then return nil end
    if res.StatusCode ~= 200 then return nil end
    local dok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not dok then return nil end
    return data
end

SS.Request = request

return SS