local rules = {
    {"side", "local"}, {"define", "function"}, {"exit", "end"},
    {"source", "if"}, {"unless", "else"}, {"another", "elseif"}, {"avoid", "then"},
    {"pwn", "for"}, {"var", "in"}, {"rush", "do"}, {"halt", "while"}, {"repeat", "repeat"}, {"until", "until"},
    {"oueq", "and"}, {"ms", "or"}, {"please", "not"}, {"be", "=="}, {"notbe", "~="},
    {"return", "return"}, {"yield", "task.wait"}, {"break", "break"}, {"continue", "continue"},

    {"hux9z_env", "getgenv"}, {"hux9z_renv", "getrenv"}, {"hux9z_fenv", "getfenv"},
    {"hux9z_reg", "getreg"}, {"hux9z_gc", "getgc"}, {"hux9z_stack", "getcallstack"},
    {"hux9z_inst", "getinstances"}, {"hux9z_nilinst", "getnilinstances"},
    {"hux9z_conn", "getconnections"}, {"hux9z_loaded", "getloadedmodules"},
    {"hux9z_scripts", "getrunningscripts"},

    {"obfhik", "hookfunction"}, {"obfmaod", "hookmetamethod"}, {"newc", "newcclosure"},
    {"nxtcaller", "checkcaller"}, {"isl", "islclosure"}, {"isc", "iscclosure"},
    {"getcon", "getconstants"}, {"setcon", "setconstant"}, {"getup", "getupvalues"},
    {"setup", "setupvalue"}, {"getproto", "getprotos"}, {"cloneref", "cloneref"},

    {"getmt", "getrawmetatable"}, {"setmt", "setrawmetatable"},
    {"setro", "setreadonly"}, {"isro", "isreadonly"},
    {"make_ro", "make_readonly"}, {"make_wr", "make_writeable"},

    {"readtring", "readfile"}, {"writetring", "writefile"}, {"appendtring", "appendfile"},
    {"listtrings", "listfiles"}, {"betring", "isfile"}, {"bepack", "isfolder"},
    {"setpack", "makefolder"}, {"deltring", "delfile"}, {"delpack", "delfolder"},
    {"loadtring", "loadfile"},

    {"world", "workspace"}, {"game", "game"}, {"getserv", "GetService"},
    {"find", "FindFirstChild"}, {"waitfor", "WaitForChild"}, {"destroy", "Destroy"},
    {"clone", "Clone"}, {"getkids", "GetChildren"}, {"getall", "GetDescendants"},
    {"isa", "IsA"}, {"players", "game:GetService('Players')"}, {"localp", "game:GetService('Players').LocalPlayer"},

    {"vec3", "Vector3.new"}, {"vec2", "Vector2.new"}, {"cf", "CFrame.new"},
    {"ang", "CFrame.Angles"}, {"rgb", "Color3.fromRGB"}, {"hsv", "Color3.fromHSV"},
    {"random", "math.random"}, {"floor", "math.floor"}, {"ceil", "math.ceil"},
    {"abs", "math.abs"}, {"clamp", "math.clamp"}, {"huge", "math.huge"},

    {"click1", "mouse1click"}, {"click2", "mouse2click"}, {"press1", "mouse1press"},
    {"rel1", "mouse1release"}, {"m_move", "mousemoveabs"}, {"m_scroll", "mousescroll"},
    {"k_press", "keypress"}, {"k_rel", "keyrelease"}, {"u_input", "game:GetService('UserInputService')"},

    {"restsend", "request"}, {"stingload", "loadstring"}, {"whoexec", "identifyexecutor"},
    {"whoami", "getexecutorname"}, {"clipmake", "setclipboard"}, {"clipget", "getclipboard"},
    {"makecap", "setfpscap"}, {"gethash", "getscripthash"}, {"getbyte", "getscriptbytecode"},
    {"fireclick", "fireclickdetector"}, {"firetouch", "firetouchinterest"}, {"fireprox", "fireproximityprompt"},

    {"draw_new", "Drawing.new"}, {"draw_clear", "cleardrawcache"}, {"draw_fonts", "Drawing.Fonts"},
    {"get_render", "getrenderproperty"}, {"set_render", "setrenderproperty"},

    {"lower", "string.lower"}, {"upper", "string.upper"}, {"split", "string.split"},
    {"format", "string.format"}, {"t_insert", "table.insert"}, {"t_remove", "table.remove"},
    {"t_find", "table.find"}, {"t_sort", "table.sort"}, {"t_clear", "table.clear"}
}


local function compileLuaZ(code)
    for _, r in ipairs(rules) do
        code = code:gsub("%f[%w]" .. r[1] .. "%f[%W]", r[2])
    end
    return code
end


return {
    run = function(customCode)
        local compiled = compileLuaZ(customCode)
        local func, err = loadstring(compiled)
        if func then
            return func()
        else
            warn("LuaZ Syntax Error: " .. tostring(err))
            print("Compiled code: ", compiled)
        end
    end
}