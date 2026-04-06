// MissLua | LuaM Obfuscator v1.0.0
// MEX = MissEX — custom 3-char encoding per character, random table per script

const MEX_POOL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~`!@#$%^&*()_+{}[]|;:\'".,<>?\\';

// Генерация рандомного MEX символа (3 char)
function randMex(pool) {
    let s = '';
    for (let i = 0; i < 3; i++) s += pool[Math.floor(Math.random() * pool.length)];
    return s;
}

// Генерация таблицы: каждый char (0-255) → несколько вариантов MEX (от 3 до 6)
function genMexTable(pool) {
    const table = {};
    for (let i = 0; i < 256; i++) {
        const variants = [];
        const count = 3 + Math.floor(Math.random() * 4); // 3-6 вариантов
        const used = new Set();
        while (variants.length < count) {
            const m = randMex(pool);
            if (!used.has(m)) { used.add(m); variants.push(m); }
        }
        table[i] = variants;
    }
    return table;
}

// Кодируем строку через MEX таблицу
function mexEncode(str, table) {
    const parts = [];
    for (let i = 0; i < str.length; i++) {
        const code = str.charCodeAt(i);
        const variants = table[code] || table[63]; // fallback '?'
        const picked = variants[Math.floor(Math.random() * variants.length)];
        parts.push('/' + picked + '/');
    }
    return parts.join('');
}

// Строим компактную таблицу для встраивания в Lua (только нужные chars)
function buildLuaTable(str, table) {
    const needed = new Set();
    for (let i = 0; i < str.length; i++) needed.add(str.charCodeAt(i));
    
    // Обратная таблица: mex → charcode
    const reverse = {};
    needed.forEach(code => {
        table[code].forEach(mex => { reverse[mex] = code; });
    });
    return reverse;
}

// Рандомное имя переменной
function rVar() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const len = 6 + Math.floor(Math.random() * 8);
    return Array.from({length: len}, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

function ri(min, max) { return min + Math.floor(Math.random() * (max - min + 1)); }

// Мусорные строки на разных языках (чтоб байтить)
const BAIT_LANGS = [
    'This is not the main code lol',
    'Это не основной код lol',
    'Це не основний код lol',
    'Este no es el código principal lol',
    'Ce n\'est pas le code principal lol',
    'Das ist nicht der Hauptcode lol',
    'これはメインコードではありません lol',
    'Ini bukan kode utama lol',
    'Bu ana kod değil lol',
    'Це не той код що ти шукаєш',
    'Ты думал тут что-то важное?',
    'Nice try. Nothing here.',
    'كود وهمي، لا شيء هنا',
    'Faux code, rien ici',
    'Falso código aqui',
];

function baitText() {
    const count = ri(1, 255);
    const parts = [];
    for (let i = 0; i < count; i++) {
        parts.push(BAIT_LANGS[Math.floor(Math.random() * BAIT_LANGS.length)]);
    }
    return parts.join(' | ');
}

// HEX в обратную сторону с / разделителем
function reverseHex(str) {
    const bytes = [];
    for (let i = 0; i < str.length; i++) {
        bytes.push(str.charCodeAt(i).toString(16).padStart(2, '0').toUpperCase());
    }
    bytes.reverse();
    return bytes.map(b => '/' + b + '/').join('');
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
        let processed = line.replace(/--\[\[.*?\]\]/g, '');
        const mlStart = processed.indexOf('--[[');
        if (mlStart !== -1) {
            const mlEnd = processed.indexOf(']]', mlStart + 4);
            if (mlEnd !== -1) { processed = processed.slice(0, mlStart) + processed.slice(mlEnd + 2); }
            else { inML = true; processed = processed.slice(0, mlStart); }
        }
        // Убираем однострочные комментарии
        processed = processed.replace(/--[^\[\n][^\n]*/g, '').trim();
        if (processed) out.push(processed);
    }
    return out.join(' ');
}

async function obfuscateLuaM(source, doMinify) {
    const pool = MEX_POOL;
    const mexTable = genMexTable(pool);

    // Имена переменных загрузчиков (рандомные)
    const vLoad  = rVar(); // основной обработчик
    const vDump  = rVar(); // защита от дампа  
    const vJunk1 = rVar(); // мусор 1
    const vJunk2 = rVar(); // мусор 2
    const vBait  = rVar(); // байт HEX

    // Имена декодера
    const vTbl   = rVar(); // MEX таблица
    const vDec   = rVar(); // decode функция
    const vS     = rVar(); // строка
    const vR     = rVar(); // результат
    const vI     = rVar(); // итератор
    const vK     = rVar(); // ключ
    const vMatch = rVar(); // match result
    const vSub   = rVar(); // string.sub
    const vChar  = rVar(); // string.char

    // Кодируем основной код
    const encoded = mexEncode(source, mexTable);

    // Строим обратную таблицу только для нужных символов
    const reverseTable = buildLuaTable(source, mexTable);

    // Сериализуем таблицу в Lua
    const tblEntries = Object.entries(reverseTable)
        .map(([mex, code]) => `["${mex}"]=${code}`)
        .join(',');

    // Мусорный байт (bait)
    const bait = baitText();
    const baitHex = reverseHex(bait);

    // Мусорный код (junk) — тоже в MEX
    const junkSrc = `local _ = ${ri(1000,9999)} local __ = _ * ${ri(2,99)} - ${ri(1,500)}`;
    const junkEncoded = mexEncode(junkSrc, mexTable);

    const lines = [];
    lines.push(`--[[ MissLua | LuaM v1.0.1 | https://misslua.pages.dev ]]`);
    lines.push(`return (function(...)`);
    lines.push(`local _A = {...}`);
    lines.push(``);

    // MEX таблица (встроена прямо в скрипт)
    lines.push(`local ${vTbl}={${tblEntries}}`);
    lines.push(``);

    // Декодер (спрятан через замыкание)
    lines.push(`local ${vSub}=string.sub`);
    lines.push(`local ${vChar}=string.char`);
    lines.push(`local ${vDec}=(function()`);
    lines.push(`    return function(${vS})`);
    lines.push(`        local ${vR}=""`);
    lines.push(`        local ${vI}=1`);
    lines.push(`        while ${vI}<=#${vS} do`);
    lines.push(`            if ${vSub}(${vS},${vI},${vI})=="/" then`);
    lines.push(`                local ${vK}=${vSub}(${vS},${vI}+1,${vI}+3)`);
    lines.push(`                local ${vMatch}=${vTbl}[${vK}]`);
    lines.push(`                if ${vMatch} then ${vR}=${vR}..${vChar}(${vMatch}) end`);
    lines.push(`                ${vI}=${vI}+5`);
    lines.push(`            else`);
    lines.push(`                ${vI}=${vI}+1`);
    lines.push(`            end`);
    lines.push(`        end`);
    lines.push(`        return ${vR}`);
    lines.push(`    end`);
    lines.push(`end)()`);
    lines.push(``);

    // Загрузчики
    lines.push(`local ${vLoad}=load or loadstring`);
    lines.push(`local ${vDump}=load or loadstring`);
    lines.push(`local ${vJunk1}=load or loadstring`);
    lines.push(`local ${vJunk2}=load or loadstring`);
    lines.push(`local ${vBait}=load or loadstring`);
    lines.push(``);

    // Мусор 1 — junk код в MEX
    lines.push(`${vJunk1}(${vDec}("${junkEncoded}"))()`);
    lines.push(``);

    // Байт блок — HEX в обратную сторону (люди будут пытаться расшифровать)
    lines.push(`${vBait}(${vDec}("${mexEncode('--[[ ' + baitHex + ' ]]', mexTable)}"))`);
    lines.push(``);

    // Мусор 2
    const junk2Src = `local _ = type(${ri(1,999)}) == "number" and ${ri(100,9999)} or ${ri(1,99)}`;
    lines.push(`${vJunk2}(${vDec}("${mexEncode(junk2Src, mexTable)}"))()`);
    lines.push(``);

    // Основной код
    lines.push(`local ${rVar()},${rVar()}=${vLoad}(${vDec}("${encoded}"))`);
    lines.push(`assert(${rVar()},${rVar()})`); // намеренно другие имена чтоб путало
    
    // Финальный запуск — переписываем правильно
    const vOut = rVar();
    const vErr = rVar();
    lines.pop(); lines.pop();
    lines.push(`local ${vOut},${vErr}=${vLoad}(${vDec}("${encoded}"))`);
    lines.push(`assert(${vOut},${vErr})`);
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

        let finalResult = result;
        if (infinity !== 'yes' && result.length > 16000) {
            let cutAt = result.lastIndexOf('\n', 15999);
            if (cutAt < 0) cutAt = 15999;
            finalResult = result.substring(0, cutAt);
        }

        return new Response(JSON.stringify({ success: true, result: finalResult, size: finalResult.length }), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
    } catch (e) {
        return new Response(JSON.stringify({ error: 'Obfuscation failed: ' + e.message }), { status: 500, headers: corsHeaders });
    }
}