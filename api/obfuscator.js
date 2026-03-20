// Nekoq Obfuscator v4 — Lua 5.1 compatible, no minifier

function rStr(l) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const len = l || (6 + Math.floor(Math.random() * 9));
    return Array.from({ length: len }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

function ri(min, max) {
    return min + Math.floor(Math.random() * (max - min + 1));
}

function toDec(data) {
    return [...data].map(b => '\\' + (b & 0xff).toString().padStart(3, '0')).join('');
}

function strToBytes(s) {
    return [...s].map(c => c.charCodeAt(0));
}

// Обфусцированное число: (r+n - r)
function mNum(n) {
    const r = ri(1000, 9000);
    return `(${r + n}-${r})`;
}

// Всегда true условия
function condTrue() {
    const k = ri(0, 4);
    if (k === 0) return 'math.pi > 3';
    if (k === 1) return 'type("") == "string"';
    if (k === 2) return 'math.floor(1.9) == 1';
    if (k === 3) return 'math.huge > 0';
    return '(2^8) == 256';
}

// Всегда false условия
function condFalse() {
    const k = ri(0, 4);
    if (k === 0) return 'math.pi < 3';
    if (k === 1) return 'type(0) == "string"';
    if (k === 2) return 'math.floor(1.9) == 2';
    if (k === 3) return 'math.huge < 0';
    return '(2^8) == 255';
}

// Мусорный блок переменных
function junkVars(count) {
    const lines = [];
    for (let i = 0; i < count; i++) {
        const a = ri(1000, 9000), b = ri(1, 500);
        lines.push(`local ${rStr()} = (${a + b}-${b})`);
    }
    return lines.join('\n');
}

// Dead code блок (никогда не выполняется)
function deadBlock() {
    const lines = [];
    const n = ri(2, 5);
    for (let i = 0; i < n; i++) {
        lines.push(`    local ${rStr()} = ${ri(1, 9999)}`);
    }
    return `if ${condFalse()} then\n${lines.join('\n')}\nend`;
}

// Шифрование исходника
function encrypt(source) {
    let data = strToBytes(source);
    // XOR с ключом
    const key = ri(1, 127);
    data = data.map((b, i) => ((b ^ (key + i * 3)) & 0xff));
    // ADD соль
    const salt = ri(1, 50);
    data = data.map(b => (b + salt) & 0xff);
    // Реверс
    data.reverse();
    return { data, key, salt };
}

function obfuscate(source) {
    const { data, key, salt } = encrypt(source);

    // Имена переменных
    const vStk  = rStr(), vPc  = rStr(), vBc  = rStr();
    const vOp   = rStr(), vRes = rStr(), vI   = rStr();
    const vB    = rStr(), vFn  = rStr(), vErr = rStr();
    const vKey  = rStr(), vSalt = rStr(), vRev = rStr();
    const vBxor = rStr();

    const payloadStr = toDec(data);

    const lines = [];

    lines.push(`--[[ Nekoq Obfuscator | wexly.vercel.app/obfuscator ]]`);
    lines.push(`return (function(...)`);

    // bxor совместимость
    lines.push(`local ${vBxor} = bit and bit.bxor or bit32 and bit32.bxor or function(a,b)`);
    lines.push(`    local r,m = 0,1`);
    lines.push(`    while a > 0 or b > 0 do`);
    lines.push(`        if a % 2 ~= b % 2 then r = r + m end`);
    lines.push(`        a = math.floor(a/2)`);
    lines.push(`        b = math.floor(b/2)`);
    lines.push(`        m = m * 2`);
    lines.push(`    end`);
    lines.push(`    return r`);
    lines.push(`end`);
    lines.push(``);

    // Мусор сверху
    lines.push(junkVars(ri(15, 25)));
    lines.push(``);
    lines.push(deadBlock());
    lines.push(``);

    // Зашифрованный payload
    lines.push(`local ${vBc} = "${payloadStr}"`);
    lines.push(`local ${vKey}  = ${mNum(key)}`);
    lines.push(`local ${vSalt} = ${mNum(salt)}`);
    lines.push(`local ${vStk}  = {}`);
    lines.push(`local ${vPc}   = ${mNum(1)}`);
    lines.push(``);

    // Мусор в середине
    lines.push(junkVars(ri(10, 20)));
    lines.push(``);
    lines.push(deadBlock());
    lines.push(``);

    // Цикл загрузки байтов в стек
    lines.push(`while ${vPc} <= #${vBc} do`);
    lines.push(`    local ${vOp} = ${vBc}:byte(${vPc})`);
    lines.push(`    table.insert(${vStk}, ${vOp})`);
    lines.push(`    ${vPc} = ${vPc} + ${mNum(1)}`);
    lines.push(`end`);
    lines.push(``);

    // Декодер
    lines.push(`local ${vRev} = {}`);
    lines.push(`for ${vI} = ${mNum(1)}, #${vStk} do`);
    lines.push(`    ${vRev}[#${vStk} - ${vI} + ${mNum(1)}] = ${vStk}[${vI}]`);
    lines.push(`end`);
    lines.push(``);
    lines.push(`local ${vRes} = ""`);
    lines.push(`for ${vI} = ${mNum(1)}, #${vRev} do`);
    lines.push(`    local ${vB} = (${vRev}[${vI}] - ${vSalt}) % ${mNum(256)}`);
    lines.push(`    ${vB} = ${vBxor}(${vB}, (${vKey} + (${vI} - ${mNum(1)}) * ${mNum(3)}) % ${mNum(256)})`);
    lines.push(`    ${vRes} = ${vRes} .. string.char(${vB})`);
    lines.push(`end`);
    lines.push(``);

    // Мусор снизу
    lines.push(deadBlock());
    lines.push(``);
    lines.push(junkVars(ri(10, 20)));
    lines.push(``);

    // Выполнение
    lines.push(`local ${vFn} = load or loadstring`);
    lines.push(`assert(${vFn}, "loadstring unavailable")`);
    lines.push(`local ${vFn}, ${vErr} = ${vFn}(${vRes})`);
    lines.push(`assert(${vFn}, ${vErr})`);
    lines.push(`return ${vFn}(...)`);
    lines.push(`end)(...)`);

    return lines.join('\n');
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
    if (code.length > 50000) return res.status(400).json({ error: 'Code too large (max 50KB)' });

    try {
        const result = obfuscate(code.trim());
        return res.status(200).json({ success: true, result, size: result.length });
    } catch (e) {
        return res.status(500).json({ error: 'Obfuscation failed: ' + e.message });
    }
}