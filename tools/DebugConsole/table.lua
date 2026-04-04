-- // Table.lua (на сервере, возвращается через loadstring)
return function(UID, sUID, URL, BUID)

    local Table = {
        Meta = {
            version   = "1.0.0",
            verAUID   = "URL_DC_BETA",   -- URL бета версии для Allowed/Special
            verStable = "URL_DC_STABLE", -- URL стабильной версии
        },

        AllowedUID = {
            -- "12345678",
        },

        SpecialUID = {
            -- "12345678",
        },

        BannedUID = {
            -- "12345678",
        },

        DisallowedURL = {
            Yomka  = "https://yomka.example.com",
            -- Alias = "https://example.com/file",
        },

        DisallowedURL_ST = {
            Yomka  = "Failed to Debug. YOMKA in BlackURL and cannot be debugged.",
            -- Alias = "Custom message here",
        },
    }
    return Table
end