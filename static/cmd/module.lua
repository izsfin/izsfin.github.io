local Security = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/security",
    Headers = { ["User-Agent"] = "hux9z/software/cmd" }
}).Body)()

local Helpers = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/helpers",
    Headers = { ["User-Agent"] = "hux9z/software/cmd" }
}).Body)()

local ModuleSystem = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/module",
    Headers = { ["User-Agent"] = "hux9z/software/cmd" }
}).Body)()