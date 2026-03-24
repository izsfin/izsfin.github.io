local llua = loadstring(game:HttpGet("..."))()
local loader = loadstring(game:HttpGet("..."))()

local using = {
    library = "library",
    meta = "meta",
    logic = {
        "main"   = "callname",
        "module" = "callname",
    }
}

if not using.library then miXconf:src_down(); return end
if not using.meta then miXconf:meta_down(); return end
if not using.logic.main then miXconf:logic_down(); return end
if not using.logic.module then miXconf:lm_down(); return end

using.logic.main.Start(using.librar, using.meta, using.logic.module, using.logic.main)

print(using.meta.project_name .. " || Loaded! || " .. using.meta.project_vers)