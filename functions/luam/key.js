// MissLua Security | /lms/key

function rVar() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const len = 6 + Math.floor(Math.random() * 8);
    return Array.from({length: len}, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

function rName16() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let s = chars[Math.floor(Math.random() * 52)];
    for (let i = 1; i < 16; i++) s += chars[Math.floor(Math.random() * chars.length)];
    return s;
}

function ri(min, max) { return min + Math.floor(Math.random() * (max - min + 1)); }

function genKey() {
    const varName = rName16();
    const vTime   = rVar();
    const vDelta  = rVar();
    const vC1     = rVar();
    const vC2     = rVar();
    const vC3     = rVar();
    const fakes   = Array.from({length: ri(2,4)}, () => `local ${rVar()} = nil`).join('\n');

    return `return (function()
local ${vTime} = tick()

local ${vC1} = function()
    local ${vDelta} = tick() - ${vTime}
    if ${vDelta} > ${ri(8,15)} then
        error("Syntax Error: unexpected token near 'end'", 0)
    end
end

local ${vC2} = function()
    if debug and debug.getinfo then
        local ok, info = pcall(debug.getinfo, 2, "S")
        if ok and info and info.what == "C" then
            error("Syntax Error: unexpected symbol near '}'", 0)
        end
    end
end

local ${vC3} = function()
    local ok = pcall(function()
        local _ = ${ri(1000,9999)} * ${ri(2,9)} - ${ri(1,500)}
    end)
    if not ok then
        error("Syntax Error: unexpected token near 'local'", 0)
    end
end

${fakes}

return {
    u = "${varName}",
    s = function()
        ${vC1}()
        ${vC2}()
        ${vC3}()
    end
}
end)()`;
}

export async function onRequest(context) {
    const { request } = context;
    const headers = {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "text/plain; charset=UTF-8",
        "Cache-Control": "no-store, no-cache",
    };
    if (request.method === "OPTIONS") return new Response(null, { status: 200, headers });
    try {
        return new Response(genKey(), { status: 200, headers });
    } catch(e) {
        return new Response(`-- error: ${e.message}`, { status: 500, headers });
    }
}