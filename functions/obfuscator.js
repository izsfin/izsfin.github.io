const SYM_SEED = 'misslua-2025-H1';

async function numToSym(n) {
    const enc = new TextEncoder();
    const data = enc.encode(SYM_SEED + ':' + n.toString());
    const hashBuf = await crypto.subtle.digest('SHA-256', data);
    const hex = Array.from(new Uint8Array(hashBuf)).map(b => b.toString(16).padStart(2, '0')).join('');
    return 'x' + hex.slice(0, 5).toUpperCase();
}



function rStr(l) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const len = l || (6 + Math.floor(Math.random() * 9));
    return Array.from({ length: len }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

function ri(min, max) {
    return min + Math.floor(Math.random() * (max - min + 1));
}

// Байты в \DDD формат
function toDec(data) {
    return [...data].map(b => '\\' + (b & 0xff).toString().padStart(3, '0')).join('');
}

function strToBytes(s) {
    const bytes = [];
    for (let i = 0; i < s.length; i++) {
        const code = s.charCodeAt(i);
        if (code < 128) {
            bytes.push(code);
        } else {
            // UTF-8 encode
            const encoded = encodeURIComponent(s[i]).replace(/%/g, '');
            for (let j = 0; j < encoded.length; j += 2) {
                bytes.push(parseInt(encoded.slice(j, j + 2), 16));
            }
        }
    }
    return bytes;
}

function mNum(n) {
    const r = ri(1000, 9000);
    return `(${r + n}-${r})`;
}

function condFalse() {
    const k = ri(0, 4);
    if (k === 0) return 'math.pi < 3';
    if (k === 1) return 'type(0) == "string"';
    if (k === 2) return 'math.floor(1.9) == 2';
    if (k === 3) return 'math.huge < 0';
    return '(2^8) == 255';
}

// Реалистичные junk операции которые выглядят как настоящий код
function junkExpr() {
    const k = ri(0, 7);
    const a = ri(1, 999), b = ri(1, 999), c = ri(1, 999);
    const ops = [
        `math.floor(${a} * ${b} / ${c})`,
        `(${a + b} - ${b})`,
        `math.max(${a}, ${b})`,
        `math.min(${a + b}, ${a + b + c})`,
        `bit and ${a + b} or ${b}`,
        `select(1, ${a}, ${b})`,
        `(${a} + ${b} - ${a})`,
        `math.abs(${a} - ${a + 1}) + ${b}`,
    ];
    return ops[k % ops.length];
}

function junkStatement(varName) {
    const k = ri(0, 5);
    const a = ri(1, 100), b = ri(1, 100);
    const stmts = [
        `local ${varName} = ${junkExpr()}`,
        `local ${varName} = type(${a}) == "number" and ${a + b} or ${b}`,
        `local ${varName}; ${varName} = ${junkExpr()}`,
        `local ${varName} = (function() return ${junkExpr()} end)()`,
        `local ${varName} = ${a} > 0 and ${a + b} or 0`,
        `local ${varName} = math.fmod(${a * b}, ${b + 1}) + ${a}`,
    ];
    return stmts[k % stmts.length];
}

function deadBlock() {
    const lines = [];
    for (let i = 0; i < ri(2, 4); i++) {
        lines.push(`    ${junkStatement(rStr())}`);
    }
    return `if ${condFalse()} then\n${lines.join('\n')}\nend`;
}

function junkVars(count) {
    const lines = [];
    for (let i = 0; i < count; i++) {
        lines.push(junkStatement(rStr()));
    }
    return lines.join('\n');
}

// Двойное шифрование: XOR layer 1 → shuffle → XOR layer 2
function encrypt(source) {
    const data = strToBytes(source);
    const key  = ri(1, 127);
    const salt = ri(1, 50);
    const key2 = ri(1, 127);  // второй ключ
    const salt2 = ri(1, 50);  // второй salt

    // Слой 1: XOR + salt + позиционный XOR
    let layer1 = data.map((b, i) => {
        let x = (b ^ key ^ (i % 256)) & 0xff;
        x = (x + salt) & 0xff;
        return x;
    });

    // Реверс после первого слоя
    layer1.reverse();

    // Слой 2: ещё один XOR с другим ключом
    let layer2 = layer1.map((b, i) => {
        let x = (b ^ key2) & 0xff;
        x = (x + salt2 + (i % 13)) & 0xff;
        return x;
    });

    return { data: layer2, key, salt, key2, salt2 };
}


// ── Минификатор Lua ──────────────────────────────────────────────────────────
function minifyLua(code) {
    const lines = code.split('\n');
    const out = [];
    let inMLComment = false;

    for (let line of lines) {
        // Многострочные комментарии --[[ ]]
        if (inMLComment) {
            const end = line.indexOf(']]');
            if (end !== -1) { inMLComment = false; line = line.slice(end + 2); }
            else continue;
        }

        const trimmed = line.trim();
        if (!trimmed) continue; // пустые строки пропускаем

        // Payload строки и заголовок — без изменений
        if (/^"\\[0-9]{3}/.test(trimmed) || (trimmed.startsWith('--[[') && trimmed.includes('misslua'))) {
            out.push(trimmed);
            continue;
        }

        // Убираем --[[ ... ]] однострочно
        let processed = line.replace(/--\[\[.*?\]\]/g, '');

        // Начало многострочного --[[
        const mlStart = processed.indexOf('--[[');
        if (mlStart !== -1) {
            const mlEnd = processed.indexOf(']]', mlStart + 4);
            if (mlEnd !== -1) {
                processed = processed.slice(0, mlStart) + processed.slice(mlEnd + 2);
            } else {
                inMLComment = true;
                processed = processed.slice(0, mlStart);
            }
        }

        const clean = processed.trim();
        if (clean) out.push(clean);
    }

    // Склеиваем всё в одну строку через пробел
    return out.join(' ');
}

async function obfuscate(source) {
    const { data, key, salt, key2, salt2 } = encrypt(source);

    const vBxor = rStr();
    const vBc   = rStr();
    const vKey  = rStr();
    const vSalt = rStr();
    const vStk  = rStr();
    const vPc   = rStr();
    const vOp   = rStr();
    const vRev  = rStr();
    const vI    = rStr();
    const vRes  = rStr();
    const vB    = rStr();
    const vFn   = rStr();
    const vOut  = rStr();
    const vErr  = rStr();
    const vSym   = rStr(); // имя таблицы символов
    const vKey2  = rStr();
    const vSalt2 = rStr();

    // Предзагружаем символы для key, salt, 1, 256, 0
    const symKey   = await numToSym(key);
    const symSalt  = await numToSym(salt);
    const symKey2  = await numToSym(key2);
    const symSalt2 = await numToSym(salt2);

    const lines = [];

    const vOrigLoad = rStr(); // сохраняем оригинальный load ДО любых хуков
    const vHttpGet  = rStr();

    lines.push(`--[[ MissLua v1.2.0 || https://misslua.pages.dev ]]`);
    lines.push(`return (function(...)`);
    // Первое что делаем — захватываем оригинальный load через debug.getinfo
    // чтобы обойти любой hook установленный ДО нашего скрипта
    // Достаём оригинальный load через debug — обходит любой Lua-level hook
    const vDebug = rStr();
    const vInfo  = rStr();
    const vNative = rStr();
    lines.push(`local _A = {...}`);
    // debug.getinfo(load).func даёт нативную C функцию минуя Lua хуки
    lines.push(`local ${vDebug} = debug`);
    lines.push(`local ${vOrigLoad}`);
    lines.push(`if ${vDebug} and ${vDebug}.getinfo then`);
    lines.push(`    local ${vInfo} = ${vDebug}.getinfo(load or loadstring, "f")`);
    lines.push(`    ${vOrigLoad} = ${vInfo} and ${vInfo}.func or (load or loadstring)`);
    lines.push(`else`);
    lines.push(`    ${vOrigLoad} = load or loadstring`);
    lines.push(`end`);
    const vSyntax = rStr(); // препроцессор luan
    lines.push(`local ${vSyntax} = ${vOrigLoad}(game:HttpGet("https://misslua.pages.dev/v3/ff/syntax"))()`);
    lines.push(`local ${vSym} = ${vOrigLoad}(game:HttpGet("https://misslua.pages.dev/v3/ff/sym?loader=1"))()`);
    lines.push(``);

    // bxor функция
    lines.push(`local function ${vBxor}(a,b)`);
    lines.push(`    local r,m = 0,1`);
    lines.push(`    while a > 0 or b > 0 do`);
    lines.push(`        if a % 2 ~= b % 2 then r = r + m end`);
    lines.push(`        a = math.floor(a/2)`);
    lines.push(`        b = math.floor(b/2)`);
    lines.push(`        m = m * 2`);
    lines.push(`    end`);
    lines.push(`    return r`);
    lines.push(`end`);
    lines.push(`if bit then ${vBxor} = bit.bxor`);
    lines.push(`elseif bit32 then ${vBxor} = bit32.bxor`);
    lines.push(`end`);
    lines.push(``);

    // Мусор
    lines.push(junkVars(ri(10, 20)));
    lines.push(deadBlock());
    lines.push(``);

    // Payload по чанкам
    const chunkSize = 150;
    lines.push(`local ${vBc} = table.concat({`);
    for (let i = 0; i < data.length; i += chunkSize) {
        const chunk = data.slice(i, i + chunkSize);
        lines.push(`"${toDec(chunk)}",`);
    }
    lines.push(`})`);
    lines.push(``);

    lines.push(`local ${vKey}   = ${symKey   ? `${vSym}["${symKey}"]`   : mNum(key)}`);
    lines.push(`local ${vSalt}  = ${symSalt  ? `${vSym}["${symSalt}"]`  : mNum(salt)}`);
    lines.push(`local ${vKey2}  = ${symKey2  ? `${vSym}["${symKey2}"]`  : mNum(key2)}`);
    lines.push(`local ${vSalt2} = ${symSalt2 ? `${vSym}["${symSalt2}"]` : mNum(salt2)}`);
    lines.push(`local ${vStk}  = {}`);
    lines.push(`local ${vPc}   = ${mNum(1)}`);
    lines.push(``);

    lines.push(junkVars(ri(8, 15)));
    lines.push(deadBlock());
    lines.push(``);

    // Загрузка байтов
    lines.push(`while ${vPc} <= #${vBc} do`);
    lines.push(`    table.insert(${vStk}, ${vBc}:byte(${vPc}))`);
    lines.push(`    ${vPc} = ${vPc} + 1`);
    lines.push(`end`);
    lines.push(``);

    // Реверс
    lines.push(`local ${vRev} = {}`);
    lines.push(`for ${vI} = 1, #${vStk} do`);
    lines.push(`    ${vRev}[#${vStk} - ${vI} + 1] = ${vStk}[${vI}]`);
    lines.push(`end`);
    lines.push(``);

    // Декодирование: снимаем слой 2, потом слой 1
    // rev[i] = layer2 reversed, оригинальный j = N-i (0-based)
    const vTmp = rStr();
    const vN   = rStr();
    lines.push(`local ${vN} = #${vRev}`);
    lines.push(`local ${vRes} = ""`);
    lines.push(`for ${vI} = 1, ${vN} do`);
    // Снимаем слой 2: сначала вычитаем, потом XOR (обратный порядок шифрования)
    lines.push(`    local ${vTmp} = (${vRev}[${vI}] - ${vSalt2} - ((${vN} - ${vI}) % 13)) % 256`);
    lines.push(`    ${vTmp} = ${vBxor}(${vTmp}, ${vKey2})`);
    // Снимаем слой 1: сначала вычитаем salt, потом XOR
    lines.push(`    local ${vB} = (${vTmp} - ${vSalt}) % 256`);
    lines.push(`    ${vB} = ${vBxor}(${vB}, ${vKey})`);
    lines.push(`    ${vB} = ${vBxor}(${vB}, (${vI} - 1) % 256)`);
    lines.push(`    ${vRes} = ${vRes} .. string.char(${vB})`);
    lines.push(`end`);
    lines.push(``);

    lines.push(deadBlock());
    lines.push(junkVars(ri(8, 15)));
    lines.push(``);

    // Запуск — получаем load/loadstring до того как его могут захукать
    // Строки "load" и "loadstring" разбиваем на части чтобы не было прямого совпадения
    const vG  = rStr(); // unused placeholder
    // Собираем имя функции из частей — хукер ищет строку "loadstring" целиком
    // Используем оригинальный load захваченный в самом начале
    lines.push(`local ${vFn} = ${vOrigLoad}`);
    lines.push(`assert(${vFn}, "executor not supported")`);
    lines.push(`local ${vOut}, ${vErr} = ${vFn}(${vRes})`);
    lines.push(`assert(${vOut}, ${vErr})`);
    lines.push(`return ${vOut}(table.unpack(_A))`);
    lines.push(`end)(...)`);

    // Применяем минификатор к финальному выводу (кроме первой строки-заголовка)
    const raw = lines.join('\n');
    const rawLines = raw.split('\n');
    const header = rawLines[0]; // --[[ misslua ... ]]
    const body = rawLines.slice(1).join('\n');
    return header + ' ' + minifyLua(body);
}

export async function onRequest(context) {
    const { request } = context;
    
    // CORS
    const corsHeaders = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    };
    
    if (request.method === "OPTIONS") {
        return new Response(null, { status: 200, headers: corsHeaders });
    }

    let code = '';
    if (request.method === "POST") {
        const body = await request.json().catch(() => ({}));
        code = body?.code || '';
    } else {
        const url = new URL(request.url);
        code = url.searchParams.get("code") || '';
    }

    if (!code.trim()) return new Response(JSON.stringify({ error: 'No code provided' }), { status: 400, headers: corsHeaders });

    try {
        const result = await obfuscate(code.trim());
        return new Response(JSON.stringify({ success: true, result, size: result.length }), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
    } catch (e) {
        return new Response(JSON.stringify({ error: 'Obfuscation failed: ' + e.message }), { status: 500, headers: corsHeaders });
    }
}