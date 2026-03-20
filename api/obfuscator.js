// Nekoq Obfuscator v5 — Lua 5.1 compatible

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

// Symbol table: число → символ через API
const SYM_CACHE = new Map();
async function fetchSym(n) {
    if (SYM_CACHE.has(n)) return SYM_CACHE.get(n);
    try {
        const base = process.env.VERCEL_URL
            ? `https://${process.env.VERCEL_URL}`
            : 'https://nekoq.vercel.app';
        const r = await fetch(`${base}/api/sym?n=${n}`);
        const d = await r.json();
        SYM_CACHE.set(n, d.sym);
        return d.sym;
    } catch {
        return null; // fallback к mNum
    }
}

function condFalse() {
    const k = ri(0, 4);
    if (k === 0) return 'math.pi < 3';
    if (k === 1) return 'type(0) == "string"';
    if (k === 2) return 'math.floor(1.9) == 2';
    if (k === 3) return 'math.huge < 0';
    return '(2^8) == 255';
}

function deadBlock() {
    const lines = [];
    for (let i = 0; i < ri(2, 4); i++) {
        lines.push(`    local ${rStr()} = ${ri(1, 9999)}`);
    }
    return `if ${condFalse()} then\n${lines.join('\n')}\nend`;
}

function junkVars(count) {
    const lines = [];
    for (let i = 0; i < count; i++) {
        const a = ri(1000, 9000), b = ri(1, 500);
        lines.push(`local ${rStr()} = (${a + b}-${b})`);
    }
    return lines.join('\n');
}

// Простое XOR шифрование с одним байтовым ключом (без накопления)
function encrypt(source) {
    const data = strToBytes(source);
    const key = ri(1, 127);
    const salt = ri(1, 50);

    const encrypted = data.map((b, i) => {
        // XOR с key XOR с (i % 256) чтобы не выходить за байт
        let x = (b ^ key ^ (i % 256)) & 0xff;
        // ADD salt
        x = (x + salt) & 0xff;
        return x;
    });

    // Реверс
    encrypted.reverse();

    return { data: encrypted, key, salt };
}


// ── Минификатор Lua ──────────────────────────────────────────────────────────
function minifyLua(code) {
    const lines = code.split('\n');
    const out = [];
    let inMLComment = false;

    for (let line of lines) {
        // Мультистрочные комментарии --[[ ... ]]
        if (inMLComment) {
            const end = line.indexOf(']]');
            if (end !== -1) { inMLComment = false; line = line.slice(end + 2); }
            else continue;
        }

        // Убираем --[[ однострочно
        line = line.replace(/--\[\[.*?\]\]/g, '');

        // Начало --[[
        const mlStart = line.indexOf('--[[');
        if (mlStart !== -1) {
            const mlEnd = line.indexOf(']]', mlStart + 4);
            if (mlEnd !== -1) {
                line = line.slice(0, mlStart) + line.slice(mlEnd + 2);
            } else {
                inMLComment = true;
                line = line.slice(0, mlStart);
            }
        }

        // Убираем однострочные комментарии (не внутри строк)
        let result = '';
        let inStr = false, strChar = null;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (inStr) {
                result += c;
                if (c === strChar && line[i-1] !== '\\') inStr = false;
            } else {
                if (c === '"' || c === "'") { inStr = true; strChar = c; result += c; }
                else if (c === '-' && line[i+1] === '-') break;
                else result += c;
            }
        }

        const clean = result.trim();
        if (clean) out.push(clean);
    }

    // Склеиваем через пробел, схлопываем множественные пробелы
    // Но добавляем разделители перед ключевыми словами чтобы не слипалось
    let joined = out.join(' ');
    joined = joined.replace(/ {2,}/g, ' ');

    // Добавляем ; после end/then/do где нужно чтобы не слипались токены
    // Лучше просто join через \n чтобы не ломать синтаксис
    return out.join('\n');
}

async function obfuscate(source) {
    const { data, key, salt } = encrypt(source);

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
    const vSym  = rStr(); // имя таблицы символов

    // Предзагружаем символы для key, salt, 1, 256, 0
    const symKey  = await fetchSym(key)  || null;
    const symSalt = await fetchSym(salt) || null;

    // Вспомогательная функция: число → sym выражение или fallback
    const S = (n) => {
        const cached = SYM_CACHE.get(n);
        return cached ? `${vSym}["${cached}"]` : mNum(n);
    };

    const lines = [];

    lines.push(`--[[ Nekoq Obfuscator | wexly.vercel.app/obfuscator ]]`);
    lines.push(`return (function(...)`);
    lines.push(`local _A = {...}`);
    lines.push(`local ${vSym} = loadstring(game:HttpGet("https://nekoq.vercel.app/api/sym?loader=1"))()`);
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
        lines.push(`    "${toDec(chunk)}",`);
    }
    lines.push(`})`);
    lines.push(``);

    lines.push(`local ${vKey}  = ${symKey ? `${vSym}["${symKey}"]` : mNum(key)}`);
    lines.push(`local ${vSalt} = ${symSalt ? `${vSym}["${symSalt}"]` : mNum(salt)}`);
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

    // Декодирование — ключ XOR с (i-1) % 256
    lines.push(`local ${vRes} = ""`);
    lines.push(`for ${vI} = 1, #${vRev} do`);
    lines.push(`    local ${vB} = (${vRev}[${vI}] - ${vSalt}) % 256`);
    lines.push(`    ${vB} = ${vBxor}(${vB}, ${vKey})`);
    lines.push(`    ${vB} = ${vBxor}(${vB}, (${vI} - 1) % 256)`);
    lines.push(`    ${vRes} = ${vRes} .. string.char(${vB})`);
    lines.push(`end`);
    lines.push(``);

    lines.push(deadBlock());
    lines.push(junkVars(ri(8, 15)));
    lines.push(``);

    // Запуск
    lines.push(`local ${vFn} = load or loadstring`);
    lines.push(`assert(${vFn}, "loadstring unavailable")`);
    lines.push(`local ${vOut}, ${vErr} = ${vFn}(${vRes})`);
    lines.push(`assert(${vOut}, ${vErr})`);
    lines.push(`return ${vOut}(table.unpack(_A))`);
    lines.push(`end)(...)`);

    // Применяем минификатор к финальному выводу
    const raw = lines.join('\n');
    return minifyLua(raw);
}

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.status(200).end();

    let code = '';
    if (req.method === 'POST') {
        code = req.body?.code || '';
    } else if (req.method === 'GET') {
        code = req.query?.code || '';
    } else {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    if (!code || !code.trim()) return res.status(400).json({ error: 'No code provided' });
    if (code.length > 100000) return res.status(400).json({ error: 'Code too large (max 100KB)' });

    try {
        const result = await obfuscate(code.trim());
        return res.status(200).json({ success: true, result, size: result.length });
    } catch (e) {
        return res.status(500).json({ error: 'Obfuscation failed: ' + e.message });
    }
}