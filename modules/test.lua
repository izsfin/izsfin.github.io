return {
    metainfo = {
        NameModule  = "TestModule",
        VersionModule = "v1.0.0",
        sversion    = "v1.0.0",
        Author      = "mewix",
        folder      = "testmodule",
        Classes     = {"Accessory", "Outfit"},
        SClasses    = {"Secret"},
        callsyntax  = "tm",
        csymbol     = "()",
        socials     = {"Website : https://ethereos.vercel.app"},
    },

    library = {
        -- Обычный аксессуар
        {
            Class       = "Accessory",
            SubClass    = "",
            Name        = "TestHat",
            Weld        = "Head",
            MeshID      = "rbxassetid://92976453142475",
            TextureID   = "rbxassetid://84600492178264",
            CFrame      = CFrame.new(0, -0.4, -0.05),
            FunctionCode = "",
            FunctionURL  = "",
        },

        -- Аксессуар с субклассом
        {
            Class       = "Accessory",
            SubClass    = "Face",
            Name        = "TestMask",
            Weld        = "Head",
            MeshID      = "rbxassetid://138741421741528",
            TextureID   = "rbxassetid://102873858608892",
            CFrame      = CFrame.new(0, 0, 0.55),
            FunctionCode = "",
            FunctionURL  = "",
        },

        -- Outfit
        {
            Class       = "Outfit",
            SubClass    = "",
            Name        = "TestOutfit",
            ShirtID     = "rbxassetid://6067501459",
            PantsID     = "rbxassetid://13692756757",
            FunctionCode = "",
            FunctionURL  = "",
        },

        -- Секретный айтем (не показывается в CMD но работает)
        {
            Class       = "Secret",
            SubClass    = "",
            Name        = "HiddenItem",
            FunctionCode = [[
                print("HiddenItem activated!")
            ]],
            FunctionURL  = "",
        },

        -- Айтем без класса (NoClass — снизу всех)
        {
            Class       = "-",
            SubClass    = "",
            Name        = "NoClassItem",
            FunctionCode = [[
                print("NoClassItem activated!")
            ]],
            FunctionURL  = "",
        },
    }
}