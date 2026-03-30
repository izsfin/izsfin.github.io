import Redis from "ioredis";
import crypto from "crypto";
const redis = new Redis(process.env.REDIS_URL);

const CHARS = "abcdefghijklmnopqrstuvwxyz0123456789";
function randFCA(n = 16) {
    let s = "";
    for (let i = 0; i < n; i++) s += CHARS[Math.floor(Math.random() * CHARS.length)];
    return s;
}

async function flushToDB(fca, tg) {
    const ghToken = process.env.GITHUB_TOKEN;
    const repo    = process.env.GITHUB_REPO;
    const date    = new Date().toLocaleDateString("ru-RU").replace(/\//g, ".");

    // --- fca.json ---
    const fcaPath = "api/db/fca.json";
    let fcaList = [];
    let fcaSha;
    try {
        const r = await fetch(`https://api.github.com/repos/${repo}/contents/${fcaPath}`,
            { headers: { Authorization: `Bearer ${ghToken}` } });
        const j = await r.json();
        fcaSha   = j.sha;
        fcaList  = JSON.parse(Buffer.from(j.content, "base64").toString());
    } catch(e) {}
    fcaList.push({ fca, tg });
    await fetch(`https://api.github.com/repos/${repo}/contents/${fcaPath}`, {
        method: "PUT",
        headers: { Authorization: `Bearer ${ghToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({
            message: `fca: add ${tg}`,
            content: Buffer.from(JSON.stringify(fcaList, null, 2)).toString("base64"),
            sha: fcaSha, branch: "main"
        })
    });

    // --- auth.json ---
    const authPath = "api/db/auth.json";
    let authDB = {};
    let authSha;
    try {
        const r = await fetch(`https://api.github.com/repos/${repo}/contents/${authPath}`,
            { headers: { Authorization: `Bearer ${ghToken}` } });
        const j = await r.json();
        authSha = j.sha;
        authDB  = JSON.parse(Buffer.from(j.content, "base64").toString());
    } catch(e) {}
    if (!authDB[date]) authDB[date] = [];
    authDB[date].push({ fca, tg });
    await fetch(`https://api.github.com/repos/${repo}/contents/${authPath}`, {
        method: "PUT",
        headers: { Authorization: `Bearer ${ghToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({
            message: `auth: ${date} @${tg}`,
            content: Buffer.from(JSON.stringify(authDB, null, 2)).toString("base64"),
            sha: authSha, branch: "main"
        })
    });
}

export default async function handler(req, res) {
    res.setHeader("Access-Control-Allow-Origin", "*");
    if (req.method !== "POST") return res.status(405).end();

    const { code, tg } = req.body;
    if (!code || !tg) return res.status(400).json({ error: "Missing fields" });

    const session = await redis.get(`auth:code:${code}`);
    if (!session) return res.status(404).json({ error: "Code not found or expired" });

    const raw = await redis.get(`auth:session:${session}`);
    if (!raw) return res.status(404).json({ error: "Session expired" });

    const sessionData = JSON.parse(raw);
    const fca   = randFCA(16);
    const token = crypto.randomBytes(32).toString("hex");

    // Update session → confirmed
    sessionData.status = "confirmed";
    sessionData.fca    = fca;
    sessionData.token  = token;
    sessionData.tg     = tg;
    await redis.set(`auth:session:${session}`, JSON.stringify(sessionData), "EX", 120);

    // Store FCA in Redis
    await redis.set(`fca:${fca}`, JSON.stringify({ tg, hwid: sessionData.hwid }));
    await redis.sadd("fca:all", fca);

    // Clean up code
    await redis.del(`auth:code:${code}`);

    // Batch flush logic
    const pending = await redis.incr("auth:pending:count");
    const lastFlush = await redis.get("auth:last:flush");
    const now = Date.now();

    if (pending >= 5 || !lastFlush || (now - parseInt(lastFlush)) > 30000) {
        await redis.set("auth:last:flush", now.toString());
        await redis.set("auth:pending:count", "0");
        flushToDB(fca, tg).catch(e => console.error("flush error:", e));
    }

    return res.json({ ok: true, fca });
}