import crypto from 'crypto';
// Nekoq Obfuscator v5 — Lua 5.1 compatible

// Symbol table — та же логика что в sym.js
const SYM_SEED = process.env.SYM_SEED || 'nekoq-2025-H1';
function numToSym(n) {
    const hash = crypto.createHash('sha256')
        .update(SYM_SEED + ':' + n.toString())
        .digest('hex');
    return 'x' + hash.slice(0, 5).toUpperCase();
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

// Symbol table: число → символ через API
const SYM_CACHE = new Map();
async function fetchSym(n) {
    if (SYM_CACHE.has(n)) return SYM_CACHE.get(n);
    try {
        // Всегда используем продакшн URL для sym API
        const r = await fetch(`https://nekoq.vercel.app/api/sym?n=${n}`, {
            headers: { 'nekoq-access': 'true' }
        });
        if (!r.ok) return null;
        const d = await r.json();
        if (!d.sym) return null;
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
        // Многострочные комментарии --[[ ]]
        if (inMLComment) {
            const end = line.indexOf(']]');
            if (end !== -1) { inMLComment = false; line = line.slice(end + 2); }
            else continue;
        }

        const trimmed = line.trim();
        if (!trimmed) continue; // пустые строки пропускаем

        // Payload строки и заголовок — без изменений
        if (/^"\\[0-9]{3}/.test(trimmed) || (trimmed.startsWith('--[[') && trimmed.includes('Nekoq'))) {
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

    // Склеиваем всё в одну строку
    // Определяем нужен ли ; между двумя строками
    function needsSemi(cur, nxt) {
        // После этих — только пробел
        if (/^(then|do|else|repeat)$/.test(cur)) return false;
        if (/elseif\b/.test(cur)) return false;
        if (cur.endsWith('(')) return false;
        if (cur.endsWith(',')) return false;
        if (/\(\.\.\.)$/.test(cur)) return false;       // (function(...)
        if (/\)$/.test(cur) && /^local\b/.test(nxt)) return false; // )\nlocal
        if (/^local function\b/.test(cur) && cur.endsWith(')')) return false;
        // Перед этими — только пробел
        if (/^(end|else|elseif|until|then|do)\b/.test(nxt)) return false;
        if (/^[,)\]\}]/.test(nxt)) return false;
        return true;
    }

    let result = '';
    for (let i = 0; i < out.length; i++) {
        const cur  = out[i];
        const next = out[i + 1];
        result += cur;
        if (!next) break;
        result += needsSemi(cur, next) ? ';' : ' ';
    }
    return result;
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

    lines.push(`--[[ Nekoq || https://nekoq.vercel.app ]]`);
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
        lines.push(`"${toDec(chunk)}",`);
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

    // Применяем минификатор к финальному выводу (кроме первой строки-заголовка)
    const raw = lines.join('\n');
    const rawLines = raw.split('\n');
    const header = rawLines[0]; // --[[ Nekoq ... ]]
    const body = rawLines.slice(1).join('\n');
    return header + ' ' + minifyLua(body);
}

export const config = { api: { bodyParser: { sizeLimit: '200kb' } } };

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.status(200).end();

    let code = '';
    if (req.method === 'POST') {
        // Vercel иногда не парсит — читаем вручную если нужно
        let body = req.body;
        if (typeof body === 'string') {
            try { body = JSON.parse(body); } catch {}
        }
        code = body?.code || '';
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