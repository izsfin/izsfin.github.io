return function(http)
    local UA   = "hux9z/software"
    local BASE = "https://nekoq.vercel.app/static/cmd/"
    
    return {
        UA      = UA,
        BASE    = BASE,
        Library = loadstring(http.request({ Url = BASE .. "library", Headers = { ["User-Agent"] = UA } }).Body)(),
        Meta    = loadstring(http.request({ Url = BASE .. "meta",    Headers = { ["User-Agent"] = UA } }).Body)(),
        Logic   = loadstring(http.request({ Url = BASE .. "logic",   Headers = { ["User-Agent"] = UA } }).Body)(),
        Module  = loadstring(http.request({ Url = BASE .. "module",  Headers = { ["User-Agent"] = UA } }).Body)()
    }
end