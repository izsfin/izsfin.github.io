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

function obfuscate(source) {
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

    const lines = [];

    lines.push(`--[[ Nekoq Obfuscator | wexly.vercel.app/obfuscator ]]`);
    lines.push(`return (function(...)`);
    lines.push(`local _A = {...}`);
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

    lines.push(`local ${vKey}  = ${mNum(key)}`);
    lines.push(`local ${vSalt} = ${mNum(salt)}`);
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
    if (code.length > 100000) return res.status(400).json({ error: 'Code too large (max 100KB)' });

    try {
        const result = obfuscate(code.trim());
        return res.status(200).json({ success: true, result, size: result.length });
    } catch (e) {
        return res.status(500).json({ error: 'Obfuscation failed: ' + e.message });
    }
}