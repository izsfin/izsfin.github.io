import Redis from "ioredis";
const redis = new Redis(process.env.REDIS_URL);

export default async function handler(req, res) {
    res.setHeader("Access-Control-Allow-Origin", "*");
    const { session } = req.query;
    if (!session) return res.status(400).json({ error: "Missing session" });

    const raw = await redis.get(`auth:session:${session}`);
    if (!raw) return res.json({ status: "expired" });

    const data = JSON.parse(raw);
    if (data.status === "confirmed") {
        return res.json({ status: "confirmed", fca: data.fca, token: data.token });
    }
    return res.json({ status: "pending" });
}