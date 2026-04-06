// MissLua | LuaM Obfuscator v2.0.0
// Блоки: /../ = мусор, \\..\\ = код (с индексом)
// MEX: только A-Z a-z 0-9 (безопасно для Lua [[]])

const MEX_POOL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

function ri(min, max) { return min + Math.floor(Math.random() * (max - min + 1)); }

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

// Генерация MEX таблицы (char → 3 варианта из пула)
function genMexTable() {
    const table = {};
    for (let i = 0; i < 256; i++) {
        const variants = new Set();
        while (variants.size < 3) {
            let s = '';
            for (let j = 0; j < 3; j++) s += MEX_POOL[Math.floor(Math.random() * MEX_POOL.length)];
            variants.add(s);
        }
        table[i] = [...variants];
    }
    return table;
}

// Кодируем строку в MEX
function mexEncode(str, table) {
    const parts = [];
    for (let i = 0; i < str.length; i++) {
        const code = str.charCodeAt(i);
        const variants = table[code] || table[63];
        parts.push(variants[Math.floor(Math.random() * variants.length)]);
    }
    return parts.join(' ');
}

// Обратная таблица только для нужных символов
function buildReverseTable(str, table) {
    const needed = new Set();
    for (let i = 0; i < str.length; i++) needed.add(str.charCodeAt(i));
    const rev = {};
    needed.forEach(code => {
        table[code].forEach(mex => { rev[mex] = code; });
    });
    return rev;
}

// Мусорные строки на разных языках
const BAIT = [
    'This is not the main code lol',
    'Это не основной код lol',
    'Це не основний код lol',
    'Este no es el código principal',
    'Ce n est pas le code principal',
    'Das ist nicht der Hauptcode',
    'これはメインコードではありません',
    'Bu ana kod degil lol',
    'Ты думал тут что-то важное?',
    'Nice try. Nothing here.',
    'كود وهمي لا شيء هنا',
    'Faux code rien ici',
    'Falso código aqui',
    '이것은 메인 코드가 아닙니다',
    'นี่ไม่ใช่รหัสหลัก',
];

function baitBlock() {
    const count = ri(1, 50);
    const parts = [];
    for (let i = 0; i < count; i++) parts.push(BAIT[Math.floor(Math.random() * BAIT.length)]);
    return parts.join(' | ');
}

function junkCode() {
    const a = ri(100, 9999), b = ri(1, 99);
    const stmts = [
        `local _ = ${a} * ${b} - ${a}`,
        `local _ = type(${a}) == "number" and ${b} or ${a}`,
        `local _ = math.floor(${a} / ${b})`,
        `local _ = math.max(${a}, ${b})`,
        `local _ = (function() return ${a + b} end)()`,
    ];
    return stmts[Math.floor(Math.random() * stmts.length)];
}

// Минификатор Lua
function minifyLua(code) {
    const lines = code.split('\n');
    const out = [];
    let inML = false;
    for (let line of lines) {
        if (inML) {
            const end = line.indexOf(']]');
            if (end !== -1) { inML = false; line = line.slice(end + 2); } else continue;
        }
        const trimmed = line.trim();
        if (!trimmed) continue;
        if (trimmed.startsWith('--') && !trimmed.startsWith('--[[')) continue;
        let p = line.replace(/--\[\[.*?\]\]/g, '');
        const ms = p.indexOf('--[[');
        if (ms !== -1) {
            const me = p.indexOf(']]', ms + 4);
            if (me !== -1) p = p.slice(0, ms) + p.slice(me + 2);
            else { inML = true; p = p.slice(0, ms); }
        }
        p = p.replace(/--[^\[\n][^\n]*/g, '').trim();
        if (p) out.push(p);
    }
    return out.join(' ');
}

async function obfuscateLuaM(source, doMinify) {
    const mexTable = genMexTable();

    // Кодируем основной код
    const encoded = mexEncode(source, mexTable);
    const revTable = buildReverseTable(source, mexTable);

    // Сериализуем обратную таблицу в Lua
    const tblStr = Object.entries(revTable)
        .map(([mex, code]) => `["${mex}"]=${code}`)
        .join(',');

    // Имена переменных
    const vName    = rVar();  // _name
    const vMex     = rVar();  // MEX таблица
    const vDec     = rVar();  // декодер
    const vArr     = rVar();  // массив (имя придёт с сервера через _name.u)
    const vRun     = rVar();  // runner
    const vOut     = rVar();  // результат
    const vErr     = rVar();  // ошибка
    const vLoad    = rVar();  // loadstring
    const vS       = rVar();
    const vR       = rVar();
    const vI       = rVar();
    const vK       = rVar();
    const vM       = rVar();
    const vParts   = rVar();  // собранные куски кода
    const vIdx     = rVar();

    // Разбиваем закодированный код на 3 куска
    const third = Math.floor(encoded.length / 3);
    const chunk1 = encoded.slice(0, third);
    const chunk2 = encoded.slice(third, third * 2);
    const chunk3 = encoded.slice(third * 2);

    // Рандомный порядок блоков
    const blocks = [
        { idx: 1, code: chunk1 },
        { idx: 2, code: chunk2 },
        { idx: 3, code: chunk3 },
    ].sort(() => Math.random() - 0.5);

    // Фейковые Run() — ничего не делают
    const fakeRunNames = Array.from({length: ri(2,4)}, () => rName16());
    const fakeRuns = fakeRunNames.map(n => `local ${n} = function() end ${n}()`).join('\n');

    // Строим массив с блоками
    let arrayContent = '\n';

    // Перемешиваем блоки с мусором
    for (const block of blocks) {
        // Мусор до
        for (let j = 0; j < ri(1, 3); j++) {
            arrayContent += `/../${baitBlock()}/../\n`;
        }
        // Код блок с индексом
        arrayContent += `\\\\[${block.idx}]${block.code}\\\\\n`;
        // Мусор после
        for (let j = 0; j < ri(1, 2); j++) {
            arrayContent += `/../${junkCode()}/../\n`;
        }
    }
    // Финальный мусор
    for (let j = 0; j < ri(2, 4); j++) {
        arrayContent += `/../${baitBlock()}/../\n`;
    }

    const lines = [];
    lines.push(`--[[ MissLua | LuaM v1.0.1 | https://misslua.pages.dev ]]`);
    lines.push(`return (function(...)`);
    lines.push(`local _A = {...}`);
    lines.push(`local ${vLoad} = load or loadstring`);
    lines.push(``);

    // Грузим key с сервера
    lines.push(`local ${vName} = ${vLoad}(game:HttpGet("https://misslua.pages.dev/lms/key"))()`);
    lines.push(`assert(${vName} and ${vName}.u and ${vName}.s, "Syntax Error")`);
    lines.push(``);

    // Запускаем защиту
    lines.push(`${vName}.s()`);
    lines.push(``);

    // MEX таблица
    lines.push(`local ${vMex} = {${tblStr}}`);
    lines.push(``);

    // Декодер
    lines.push(`local ${vDec} = function(${vS})`);
    lines.push(`    local ${vR} = ""`);
    lines.push(`    local ${vI} = 1`);
    lines.push(`    local _t = {}`);
    lines.push(`    for w in (${vS} .. " "):gmatch("(%S+)%s") do _t[#_t+1] = w end`);
    lines.push(`    for _,${vK} in ipairs(_t) do`);
    lines.push(`        local ${vM} = ${vMex}[${vK}]`);
    lines.push(`        if ${vM} then ${vR} = ${vR} .. string.char(${vM}) end`);
    lines.push(`    end`);
    lines.push(`    return ${vR}`);
    lines.push(`end`);
    lines.push(``);

    // Фейковые Run()
    lines.push(fakeRuns);
    lines.push(``);

    // Массив — имя берём из _name.u
    lines.push(`local ${vArr}`);
    lines.push(`do`);
    lines.push(`    local _n = ${vName}.u`);
    lines.push(`    ${vArr} = [[${arrayContent}]]`);
    lines.push(`end`);
    lines.push(``);

    // Runner — парсит блоки \\ [idx] code \\, сортирует, декодирует, запускает
    lines.push(`local ${vParts} = {}`);
    lines.push(`for ${vIdx}, chunk in (${vArr}):gmatch("\\\\\\\\%[(%d+)%]([^\\\\]-)\\\\\\\\") do`);
    lines.push(`    ${vParts}[tonumber(${vIdx})] = chunk`);
    lines.push(`end`);
    lines.push(``);

    // Собираем куски в правильном порядке
    lines.push(`local _full = ""`);
    lines.push(`for _i = 1, #${vParts} do _full = _full .. (${vParts}[_i] or "") end`);
    lines.push(``);

    // Декодируем и запускаем
    lines.push(`local ${vOut}, ${vErr} = ${vLoad}(${vDec}(_full))`);
    lines.push(`assert(${vOut}, ${vErr} or "Syntax Error")`);
    lines.push(`return ${vOut}(table.unpack(_A))`);
    lines.push(`end)(...)`);

    const raw = lines.join('\n');
    if (doMinify) {
        const rawLines = raw.split('\n');
        const header = rawLines[0];
        const body = rawLines.slice(1).join('\n');
        return header + ' ' + minifyLua(body);
    }
    return raw;
}

export async function onRequest(context) {
    const { request } = context;

    const corsHeaders = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") return new Response(null, { status: 200, headers: corsHeaders });

    let code = '', minify = 'yes', infinity = 'yes';

    if (request.method === "POST") {
        const body = await request.json().catch(() => ({}));
        code = body?.code || '';
        minify = body?.minify || 'yes';
        infinity = body?.infinity || 'yes';
    } else {
        const url = new URL(request.url);
        code = url.searchParams.get("code") || '';
        minify = url.searchParams.get("minify") || 'yes';
        infinity = url.searchParams.get("infinity") || 'yes';
    }

    if (!code.trim()) return new Response(JSON.stringify({ error: 'No code provided' }), { status: 400, headers: corsHeaders });
    if (code.length > 100000) return new Response(JSON.stringify({ error: 'Code too large (max 100KB)' }), { status: 400, headers: corsHeaders });

    try {
        const result = await obfuscateLuaM(code.trim(), minify !== 'no');

        let final = result;
        if (infinity !== 'yes' && result.length > 16000) {
            let cut = result.lastIndexOf('\n', 15999);
            if (cut < 0) cut = 15999;
            final = result.substring(0, cut);
        }

        return new Response(JSON.stringify({ success: true, result: final, size: final.length }), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
    } catch(e) {
        return new Response(JSON.stringify({ error: 'Obfuscation failed: ' + e.message }), { status: 500, headers: corsHeaders });
    }
}