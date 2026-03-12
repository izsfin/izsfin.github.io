return {
    metainfo = {
        NameModule   = "TestModule",
        VersionModule = "v1.0.0",
        sversion     = "v1.0.0",
        Author       = "mewix",
        folder       = "testmodule",
        callsyntax   = "tm",
        csymbol      = "()",
        Classes      = {"Outfit", "Accessory"},
        socials      = {"Website : https://ethereos.vercel.app"},
    },
    library = {
        {
            Class        = "Outfit",
            Name         = "TestOutfit",
            FunctionCode = [[
                changeoutfit({ shirt = "rbxassetid://6067501459", pants = "rbxassetid://13692756757" })
            ]],
        },
        {
            Class        = "Accessory",
            Name         = "TestHat",
            FunctionCode = [[
                addaccessory({ name = "testhat", mesh = "rbxassetid://73083430479187", texture = "rbxassetid://104381302798685", weld = "Head", pos = {0, 0.1, 0}, rt = {0, 0, 0} })
            ]],
        },
        {
            Class        = "secret",
            Name         = "SecretItem",
            FunctionCode = [[
                print("secret item works!")
            ]],
        },
    }
}