-- // Table.lua
local Table = {
    Meta = {
        version   = "1.0.0",
        verAUID   = "URL_DC_BETA",
        verStable = "URL_DC_STABLE",
    },

    AllowedUID = {},
    SpecialUID = {},
    BannedUID  = {},

    DisallowedURL = {
        Yomka = "https://yomka.example.com",
    },

    DisallowedURL_ST = {
        Yomka = "Failed to Debug. YOMKA in BlackURL and cannot be debugged.",
    },
}

return Table