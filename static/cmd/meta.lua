-- XMS | Meta Info + Config
-- Host: wexly-api.vercel.app/xms/meta
-- UA required: XMS-Loader-v1

local canswer = "please, try later!"

local meta = {

    -- ========================================================
    -- META INFO
    -- ========================================================
    project_name    = "JSx32",
    project_devs    = "hux9z",
    project_vers    = "v2.14.0",
    project_svers   = "³²",
    project_catalog = "https://nekoq.vercel.app/catalog",
    project_discord = ".gg/TRPZg4Xfkq",

    -- ========================================================
    -- ERROR HANDLERS
    -- ========================================================
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

return meta