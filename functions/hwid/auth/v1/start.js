import Redis from "ioredis";
import crypto from "crypto";
const redis = new Redis(process.env.REDIS_URL);

function randCode() {
    const len = 6 + Math.floor(Math.random() * 4); // 6-9
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let s = "";
    for (let i = 0; i < len; i++) s += chars[Math.floor(Math.random() * chars.length)];
    return s;
}

export default async function handler(req, res) {
    res.setHeader("Access-Control-Allow-Origin", "*");
    if (req.method !== "POST") return res.status(405).end();
    const { hwid } = req.body;
    if (!hwid) return res.status(400).json({ error: "Missing hwid" });

    const code    = randCode();
    const session = crypto.randomBytes(16).toString("hex");

    await redis.set(`auth:session:${session}`, JSON.stringify({
        hwid, code, status: "pending"
    }), "EX", 600); // 10 min

    await redis.set(`auth:code:${code}`, session, "EX", 600);

    return res.json({ ok: true, code, session });
}