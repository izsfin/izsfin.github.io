// ─────────────────────────────────────────────────────────────────────────────
// NixuMO Obfuscator — Vercel API endpoint
// POST /api/obfuscator  { code: "print('hi')" }
// GET  /api/obfuscator?code=...
// ─────────────────────────────────────────────────────────────────────────────

// ── Helpers ──────────────────────────────────────────────────────────────────

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

function mNum(n) {
    const r = ri(1000, 9000);
    return `(${r + n}-${r})`;
}

function mBoolFalse() {
    const a = ri(100, 9999);
    return `(9999-9999)>(${a + 1}-${a})`;
}

// ── Invariant checks ─────────────────────────────────────────────────────────

function invariantTrue() {
    const kind = ri(0, 8);
    if (kind === 0) return 'math.pi > 3';
    if (kind === 1) return 'math.huge > 1e300';
    if (kind === 2) return '(math.pi * math.pi) > 9';
    if (kind === 3) {
        const s = Array.from({ length: ri(3, 10) }, () => 'abcdefghijklmnopqrstuvwxyz'[ri(0, 25)]).join('');
        return `string.len("${s}") > 0`;
    }
    if (kind === 4) return 'type("") == "string"';
    if (kind === 5) return 'tostring(0) == "0"';
    if (kind === 6) return 'math.floor(1.9) == 1';
    if (kind === 7) {
        const a = ri(1, 100), b = ri(1, 100);
        return `math.max(${a},${b}) >= ${Math.min(a, b)}`;
    }
    return '(2^8) == 256';
}

function invariantFalse() {
    const kind = ri(0, 6);
    if (kind === 0) return 'math.pi < 3';
    if (kind === 1) return 'math.huge < 1';
    if (kind === 2) return '(math.pi * math.pi) < 9';
    if (kind === 3) return 'type(0) == "string"';
    if (kind === 4) return 'math.floor(1.9) == 2';
    if (kind === 5) return 'tostring(1) == "0"';
    return '(2^8) == 255';
}

function invariantGuardFake(body) {
    return `if ${invariantFalse()} then\n${body}\nend`;
}

function invariantBlock() {
    const lines = Array.from({ length: ri(3, 7) }, () => {
        const vn = rStr();
        return `    local ${vn} = ${mNum(ri(1, 200))} ~ ${mNum(ri(1, 127))}`;
    });
    return invariantGuardFake(lines.join('\n'));
}

// ── Fake bytecode block ───────────────────────────────────────────────────────

function fakeBytecodeBlock(varName) {
    const arr = Array.from({ length: ri(80, 200) }, () => ri(0, 255));
    const arrStr = '{' + arr.join(',') + '}';
    const loopVar = rStr(), op1 = rStr(), op2 = rStr();
    const body = `    for ${loopVar}=${mNum(1)},#${varName} do
        local ${op1} = ${varName}[${loopVar}] ~ ${loopVar}
        local ${op2} = (${op1} + ${mNum(ri(1, 127))}) % ${mNum(256)}
        ${varName}[${loopVar}] = ${op2} ~ ${op1}
    end`;
    return `local ${varName} = ${arrStr}\n${invariantGuardFake(body)}`;
}

// ── Junk variable block ───────────────────────────────────────────────────────

function junkBlock(count) {
    count = count || ri(40, 90);
    const lines = [];
    let prev = null;
    for (let i = 0; i < count; i++) {
        const a = ri(1000, 9000), b = ri(1000, 9000);
        const vname = rStr();
        if (prev && Math.random() < 0.4) {
            lines.push(`local ${vname} = ${prev} + ${mNum(ri(1, 99))}`);
        } else {
            lines.push(`local ${vname} = (${a + b}-${b})`);
        }
        prev = vname;
    }
    return lines.join('\n');
}

// ── Encryption layers ─────────────────────────────────────────────────────────

function encryptPayload(source) {
    let data = strToBytes(source);

    // Layer A: ROT-N
    const rot = ri(1, 127);
    data = data.map(b => (b + rot) % 256);

    // Layer B: XOR + position + salt1
    const salt1 = ri(10, 60);
    data = data.map((b, i) => (b ^ (salt1 + i)) % 256);

    // Layer C: ADD salt2
    const salt2 = ri(5, 40);
    data = data.map(b => (b + salt2) % 256);

    // Layer D: reverse
    data.reverse();

    return { data, rot, salt1, salt2 };
}

// ── VM opcodes ────────────────────────────────────────────────────────────────

function makeOpcodes() {
    const pool = Array.from({ length: 255 }, (_, i) => i + 1);
    // Fisher-Yates shuffle
    for (let i = pool.length - 1; i > 0; i--) {
        const j = ri(0, i);
        [pool[i], pool[j]] = [pool[j], pool[i]];
    }
    const names = ['PUSH','DECODE','ADD','XOR','MOV','NOP','JMP','CMP','ROT','POP',
                   'NOT','AND','OR','SHL','SHR','MUL','DIV','HALT','CALL','RET'];
    const ops = {};
    names.forEach((name, i) => { ops[name] = pool[i]; });
    return ops;
}

// ── Fake op cases ─────────────────────────────────────────────────────────────

function fakeOpCases(ops, v, exclude) {
    return Object.entries(ops)
        .filter(([name]) => !exclude.has(name))
        .map(([, val]) => {
            const iv = rStr(), iv2 = rStr(), iv3 = rStr();
            const innerDead = `            local ${iv3} = ${iv2} * ${mNum(2)}\n            ${v.res} = string.char(${iv3} % ${mNum(256)})`;
            return `        elseif ${v.op_arg} == ${mNum(val)} then
            local ${iv} = ${mNum(ri(1, 200))}
            local ${iv2} = ${iv} ~ ${mNum(ri(1, 127))}
            if ${invariantFalse()} then
${innerDead}
            end`;
        }).join('\n');
}

// ── Minifier ──────────────────────────────────────────────────────────────────

function minifyLua(code) {
    const lines = code.split('\n');
    const out = [];
    for (let line of lines) {
        const stripped = line.trim();
        if (stripped.startsWith('--')) continue;
        let result = '';
        let inStr = false, strChar = null;
        for (let i = 0; i < stripped.length; i++) {
            const c = stripped[i];
            if (inStr) {
                result += c;
                if (c === strChar && (i === 0 || stripped[i - 1] !== '\\')) inStr = false;
            } else {
                if (c === '"' || c === "'") { inStr = true; strChar = c; result += c; }
                else if (c === '-' && stripped[i + 1] === '-') break;
                else result += c;
            }
        }
        const clean = result.trim();
        if (clean) out.push(clean);
    }
    return out.join(' ').replace(/ {2,}/g, ' ');
}

// ── Main obfuscate ──────────────Minify = false─────────────────────────────────────────

function obfuscate(source) {   
    const { data: payload, rot, salt1, salt2 } = encryptPayload(source);

    // Dynamic key table
    const junkSize = 40;
    const junkArr = Array.from({ length: junkSize }, () => ri(1, 255));
    const idxRot = ri(0, junkSize - 1);
    const idxS1  = ri(0, junkSize - 1);
    const idxS2  = ri(0, junkSize - 1);
    const maskRot = ri(1, 255), maskS1 = ri(1, 255), maskS2 = ri(1, 255);
    junkArr[idxRot] = rot   ^ maskRot;
    junkArr[idxS1]  = salt1 ^ maskS1;
    junkArr[idxS2]  = salt2 ^ maskS2;
    const junkTbl = '{' + junkArr.join(',') + '}';

    const v = {};
    for (const k of ['bc','stk','pc','op','vm','op_arg','val','res','tmp','b','final','jtbl','k_rot','k_s1','k_s2','rev','idx']) {
        v[k] = rStr();
    }

    const ops = makeOpcodes();
    const fakeNames = Array.from({ length: ri(3, 6) }, rStr);
    const fakeBlocks = fakeNames.map(fakeBytecodeBlock).join('\n');
    const fakeCases = fakeOpCases(ops, v, new Set(['PUSH', 'DECODE']));

    const junkTop    = junkBlock(ri(50, 90));
    const junkMiddle = junkBlock(ri(30, 60));
    const junkBottom = junkBlock(ri(50, 90));

    const lsStr = toDec(strToBytes('loadstring'));
    const prStr = toDec(strToBytes('print("'));

    const invBlock1 = invariantBlock();
    const invBlock2 = invariantBlock();
    const invBlock3 = invariantBlock();

    const decodeBody = `            local ${v.rev} = {}
            for ${v.idx} = ${mNum(1)}, #${v.stk} do
                ${v.rev}[#${v.stk} - ${v.idx} + ${mNum(1)}] = ${v.stk}[${v.idx}]
            end
            local ${v.res} = ""
            for ${v.idx} = ${mNum(1)}, #${v.rev} do
                local ${v.b} = (${v.rev}[${v.idx}] - ${v.k_s2}) % ${mNum(256)}
                ${v.b} = (${v.b} ~ (${v.k_s1} + ${v.idx} - ${mNum(1)})) % ${mNum(256)}
                ${v.b} = (${v.b} - ${v.k_rot}) % ${mNum(256)}
                ${v.res} = ${v.res} .. string.char(${v.b})
            end
            return ${v.res}`;

    const decoyRes = rStr(), decoyB = rStr(), decoyI = rStr();
    const decoyBody = `            local ${decoyRes} = ""
            for ${decoyI} = ${mNum(1)}, #${v.stk} do
                local ${decoyB} = ${v.stk}[${decoyI}] ~ ${mNum(ri(1, 255))}
                ${decoyRes} = ${decoyRes} .. string.char(${decoyB} % ${mNum(256)})
            end
            return ${decoyRes}`;

    const lua = `return (function(...)
${junkTop}
${invBlock1}
    local ${v.bc} = "${toDec(payload)}"
    local ${v.stk} = {}
    local ${v.pc} = ${mNum(1)}
    local ${v.jtbl} = ${junkTbl}
    local ${v.k_rot} = (${v.jtbl}[${mNum(idxRot + 1)}] ~ ${mNum(maskRot)})
    local ${v.k_s1}  = (${v.jtbl}[${mNum(idxS1 + 1)}]  ~ ${mNum(maskS1)})
    local ${v.k_s2}  = (${v.jtbl}[${mNum(idxS2 + 1)}]  ~ ${mNum(maskS2)})
${fakeBlocks}
${invBlock2}
${junkMiddle}
    local function ${v.vm}(${v.op_arg}, ${v.val})
        local ${v.tmp} = ${junkTbl}
        if ${v.op_arg} == ${mNum(ops.PUSH)} then
            table.insert(${v.stk}, ${v.val})
${fakeCases}
        elseif ${v.op_arg} == ${mNum(ops.DECODE)} then
            if ${invariantTrue()} then
${decodeBody}
            else
${decoyBody}
            end
        end
    end
    while ${v.pc} <= #${v.bc} do
        local ${v.op} = ${v.bc}:byte(${v.pc})
        ${v.vm}(${mNum(ops.PUSH)}, ${v.op})
        ${v.pc} = ${v.pc} + ${mNum(1)}
    end
${invBlock3}
    local ${v.final} = ${v.vm}(${mNum(ops.DECODE)})
    local ${v.tmp} = "${lsStr}"
    local ${v.res} = "${prStr}"
    return loadstring(${v.res} .. ${v.final} .. "\\034\\041")()
${junkBottom}
end)(...)`;

    const header = '--[[ v2.14.6 NixuMO | ethereos.vercel.app/obfuscator ]]';
     return header + ' ' + minifyLua(lua);
}
//     return header + ' ' + minifyLua(lua);
//     return header + '\n' + (minify ? minifyLua(lua) : lua);
// ── Vercel handler ────────────────────────────────────────────────────────────

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

    if (!code || !code.trim()) {
        return res.status(400).json({ error: 'No code provided' });
    }

    if (code.length > 50000) {
        return res.status(400).json({ error: 'Code too large (max 50KB)' });
    }

    try {
        const result = obfuscate(code.trim());
        return res.status(200).json({
            success: true,
            result,
            size: result.length
        });
    } catch (e) {
        return res.status(500).json({ error: 'Obfuscation failed: ' + e.message });
    }
}