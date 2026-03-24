local canswer = "please, try later!"
local mi_loader = loadstring(http.request({
    Url = "https://nekoq.vercel.app/static/cmd/meta",
    Headers = { ["User-Agent"] = "hux9z/software/static/cmd" }
}).Body)
local mi = {
    project_name    = "XMS",
    project_devs    = "ximeax",
    project_vers    = "v2.13.2a",
    project_catalog = "https://wexly.vercel.app/catalog",
    project_discord = ".gg/TRPZg4Xfkq",

    down = function(self)
        warn(self.project_name .. " | No one of static servers responded, " .. canswer)
    end,

    crash = function(self)
        warn(self.project_name .. " | Reload script, or get new version")
    end,

    mi_down = function(self)
        warn(self.project_name .. " | Meta Info not answer, " .. canswer)
    end,

    md_down = function(self)
        warn(self.project_name .. " | Module System not answer, " .. canswer)
    end,

    logic_down = function(self)
        warn(self.project_name .. " | Logic not answer, " .. canswer)
    end,

    folder_down = function(self)
        warn(self.project_name .. " | Folder Path not answer, " .. canswer)
    end,

    lib_down = function(self)
        warn(self.project_name .. " | Library not answer, " .. canswer)
    end,

    nowifi = function(self)
        warn(self.project_name .. " | Buy the WiFi / Internet")
    end,
}

return miXconf