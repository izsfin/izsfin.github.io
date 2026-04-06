// MissLua Security | /lms/key
// Отдаёт Lua таблицу: { u = "имя переменной", s = функция защиты }

function rName() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let name = '';
    // Первый символ всегда буква
    name += chars[Math.floor(Math.random() * 52)];
    for (let i = 1; i < 16; i++) {
        name += chars[Math.floor(Math.random() * chars.length)];
    }
    return name;
}

function ri(min, max) { return min + Math.floor(Math.random() * (max - min + 1)); }

function rVar() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const len = 6 + Math.floor(Math.random() * 8);
    return Array.from({length: len}, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

function genKey() {
    const varName = rName();

    // Рандомные имена для переменных внутри защиты
    const vEnv     = rVar();
    const vOld     = rVar();
    const vInfo    = rVar();
    const vStack   = rVar();
    const vTime    = rVar();
    const vDelta   = rVar();
    const vFake1   = rVar();
    const vFake2   = rVar();
    const vFake3   = rVar();
    const vThread  = rVar();

    // Фейковые loadstring-и которые ничего не делают
    const fakeLoads = [];
    for (let i = 0; i < ri(2, 4); i++) {
        const v = rVar();
        const fakeUrl = `https://misslua.pages.dev/v3/ff/lms/f${ri(1000,9999)}`;
        fakeLoads.push(`    local ${v} = loadstring(game:HttpGet("${fakeUrl}")) ${v} = nil`);
    }

    const lua = `return (function()
    -- MissLua Security Layer
    local ${vTime} = tick()
    local ${vEnv} = getfenv and getfenv(0) or nil
    local ${vOld} = loadstring

    -- Проверка getfenv хука
    local ${vFake1} = function()
        if ${vEnv} then
            local ${vInfo} = debug and debug.getinfo and debug.getinfo(1, "f")
            if ${vInfo} and ${vInfo}.func ~= ${vOld} then
                error("Syntax Error: unexpected token near 'local'", 0)
            end
        end
    end

    -- Проверка таймера (дампер тормозит)
    local ${vFake2} = function()
        local ${vDelta} = tick() - ${vTime}
        if ${vDelta} > ${ri(8, 15)} then
            error("Syntax Error: unexpected token near 'end'", 0)
        end
    end

    -- Проверка debug.getinfo стека
    local ${vFake3} = function()
        if debug and debug.getinfo then
            local ${vStack} = debug.getinfo(2, "S")
            if ${vStack} and ${vStack}.what == "C" then
                error("Syntax Error: unexpected symbol near '}'", 0)
            end
        end
    end

    -- Фейковые вызовы (выглядят подозрительно для реверсера)
${fakeLoads.join('\n')}

    return {
        u = "${varName}",
        s = function()
            ${vFake1}()
            ${vFake2}()
            ${vFake3}()
        end
    }
end)()`;

    return lua;
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
        const lua = genKey();
        return new Response(lua, { status: 200, headers });
    } catch(e) {
        return new Response(`-- error: ${e.message}`, { status: 500, headers });
    }
}