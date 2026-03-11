import Redis from "ioredis";
import crypto from "crypto";
const redis = new Redis(process.env.REDIS_URL);

export default async function handler(req, res) {
    res.setHeader("Access-Control-Allow-Origin", "*");
    if (req.method !== "POST") return res.status(405).end();

    const { fca, hwid } = req.body;
    if (!fca || !hwid) return res.status(400).json({ error: "Missing fields" });

    const raw = await redis.get(`fca:${fca}`);
    if (!raw) return res.status(404).json({ ok: false, error: "FCA not found" });

    const token = crypto.randomBytes(32).toString("hex");
    await redis.set(`token:${token}`, raw, "EX", 60 * 60 * 24 * 30);
    return res.json({ ok: true, token });
}