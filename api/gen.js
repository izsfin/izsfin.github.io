// ─────────────────────────────────────────────────────────────────────────────
// Key Generator — POST/GET /api/gen
// GET  ?days=1&client=web
// POST { days, client }
// ─────────────────────────────────────────────────────────────────────────────

import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// Duration labels for key format: Nixu!{LABEL}{RAND}
const DURATION_LABEL = {
    0.5: '12H',
    1:   '1D',
    3:   '3D',
    7:   '7D',
    30:  '30D',
    90:  '90D'
};

// Random string: digits + uppercase letters
function randStr(len) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let s = '';
    for (let i = 0; i < len; i++) s += chars[Math.floor(Math.random() * chars.length)];
    return s;
}

function generateKeyString(days) {
    const label = DURATION_LABEL[days] || days + 'D';
    return `Nixu!${label}${randStr(6)}`;
}

// Cleanup expired keys and collect them in deaded set
async function cleanupExpired() {
    const keys = await redis.smembers('keys:active');
    const deaded = [];

    for (const key of keys) {
        const exists = await redis.exists(`key:${key}`);
        if (!exists) {
            // Key expired — move to deaded
            await redis.srem('keys:active', key);
            deaded.push(key);
        }
    }

    if (deaded.length >= 2) {
        // Store as deaded set
        const deadedObj = {};
        deaded.forEach(k => { deadedObj[k] = true; });
        await redis.set('keys:deaded', JSON.stringify(deadedObj));
    }
}

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') return res.status(200).end();

    let days, client;

    if (req.method === 'POST') {
        days   = parseFloat(req.body?.days);
        client = req.body?.client || 'unknown';
    } else {
        days   = parseFloat(req.query?.days);
        client = req.query?.client || 'unknown';
    }

    if (!days || isNaN(days)) {
        return res.status(400).json({ error: 'Invalid days parameter' });
    }

    const validDurations = [0.5, 1, 3, 7, 30, 90];
    if (!validDurations.includes(days)) {
        return res.status(400).json({ error: 'Invalid duration' });
    }

    try {
        // Cleanup expired before generating
        await cleanupExpired();

        // Generate unique key
        let keyStr;
        let attempts = 0;
        do {
            keyStr = generateKeyString(days);
            attempts++;
            if (attempts > 20) return res.status(500).json({ error: 'Key generation failed' });
        } while (await redis.exists(`key:${keyStr}`));

        // TTL in seconds
        const ttl = Math.floor(days * 24 * 60 * 60);

        // Store key data
        const keyData = {
            key: keyStr,
            days,
            client,
            created: Date.now(),
            expires: Date.now() + ttl * 1000
        };

        await redis.set(`key:${keyStr}`, JSON.stringify(keyData), 'EX', ttl);
        await redis.sadd('keys:active', keyStr);

        return res.status(200).json({
            success: true,
            key: keyStr,
            days,
            expires: keyData.expires
        });

    } catch (e) {
        console.error('Key gen error:', e.message);
        return res.status(500).json({ error: 'Server error: ' + e.message });
    }
}