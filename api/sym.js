// api/sym.js
// GET /api/sym?n=875 → "x82631" (символьный код для числа 875)
// GET /api/sym/loader → Lua код таблицы (только для Roblox)

import crypto from 'crypto';

const SEED = process.env.SYM_SEED || 'nekoq-2025-H1';

// Число → символьный код (детерминировано по seed)
function numToSym(n, seed) {
    const hash = crypto.createHash('sha256')
        .update(seed + ':' + n.toString())
        .digest('hex');
    // 5 hex символов = читается как xNNNNN
    return 'x' + hash.slice(0, 5).toUpperCase();
}

// Символьный код → реальное число (обратная функция через lookup)
// Храним кеш на время запроса не нужен — детерминировано

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');

    const ua = (req.headers['user-agent'] || '').toLowerCase();
    const isRoblox = ua.includes('roblox') || ua === '' || ua === 'unknown'
        || req.headers['nekoq-access'] === 'true';

    // /api/sym?loader=1 — отдаём Lua таблицу (только Roblox)
    if (req.query?.loader === '1') {
        if (!isRoblox) return res.status(403).send('-- Forbidden');

        // Генерируем таблицу для диапазона -500..9999 (покрывает все числа в обфускаторе)
        const entries = [];
        for (let n = -500; n <= 9999; n++) {
            const sym = numToSym(n, SEED);
            entries.push(`["${sym}"]=${n}`);
        }

        const lua = `return {${entries.join(',')}}`;
        res.setHeader('Content-Type', 'text/plain');
        return res.status(200).send(lua);
    }

    // /api/sym?n=875 — отдаём символ для числа (для obfuscator.js)
    const n = parseInt(req.query?.n);
    if (isNaN(n)) return res.status(400).json({ error: 'Invalid number' });

    return res.status(200).json({ sym: numToSym(n, SEED) });
}