import Redis from "ioredis";
const redis = new Redis(process.env.REDIS_URL);

export default async function handler(req, res) {
    if (req.method !== "POST") return res.status(405).end();

    const update = req.body;
    if (!update.message) return res.status(200).end();

    const msg      = update.message;
    const chatId   = msg.chat.id;
    const username = (msg.from?.username || "").toLowerCase();
    const text     = (msg.text || "").trim();

    if (username) await redis.set(`tg:chatid:${username}`, chatId.toString());

    // /start
    if (text === "/start") {
        return res.json({
            method: "sendMessage",
            chat_id: chatId,
            parse_mode: "Markdown",
            text: `👋 Hello @${username}!\n\nWelcome to *wexly Auth Bot*.\n\nTo authorize your device go to:\nhttps://wexly.vercel.app/auth\n\nThen send your auth code here.`
        });
    }

    // Auth code (6-9 chars uppercase+digits)
    if (/^[A-Z2-9]{6,9}$/.test(text)) {
        const session = await redis.get(`auth:code:${text}`);
        if (!session) {
            return res.json({
                method: "sendMessage",
                chat_id: chatId,
                text: "❌ Code not found or expired.\n\nGet a new one at: https://wexly.vercel.app/auth"
            });
        }

        const raw = await redis.get(`auth:session:${session}`);
        if (!raw) {
            return res.json({
                method: "sendMessage",
                chat_id: chatId,
                text: "❌ Session expired. Please restart auth."
            });
        }

        const sessionData = JSON.parse(raw);
        const fca   = Array.from({length: 16}, () => "abcdefghijklmnopqrstuvwxyz0123456789"[Math.floor(Math.random() * 36)]).join("");
        const crypto = await import("crypto");
        const token  = crypto.default.randomBytes(32).toString("hex");

        sessionData.status = "confirmed";
        sessionData.fca    = fca;
        sessionData.token  = token;
        sessionData.tg     = username;
        await redis.set(`auth:session:${session}`, JSON.stringify(sessionData), "EX", 120);
        await redis.set(`fca:${fca}`, JSON.stringify({ tg: username, hwid: sessionData.hwid }));
        await redis.sadd("fca:all", fca);
        await redis.del(`auth:code:${text}`);

        // Batch flush
        const pending   = await redis.incr("auth:pending:count");
        const lastFlush = await redis.get("auth:last:flush");
        const now       = Date.now();
        if (pending >= 5 || !lastFlush || (now - parseInt(lastFlush)) > 30000) {
            await redis.set("auth:last:flush", now.toString());
            await redis.set("auth:pending:count", "0");
            flushToDB(fca, username).catch(e => console.error("flush:", e));
        }

        return res.json({
            method: "sendMessage",
            chat_id: chatId,
            parse_mode: "Markdown",
            text: `✅ *Successfully authorized!*\n\nFCA: \`${fca}\`\n\nSave this code for fast login on any device.`
        });
    }

    return res.json({
        method: "sendMessage",
        chat_id: chatId,
        text: "❓ Send your auth code from the site, or type /start for help."
    });
}

async function flushToDB(fca, tg) {
    const ghToken = process.env.GITHUB_TOKEN;
    const repo    = process.env.GITHUB_REPO;
    const date    = new Date().toLocaleDateString("ru-RU").replace(/\//g, ".");

    for (const [path, newEntry, isArray] of [
        ["api/db/fca.json",  { fca, tg }, true],
        ["api/db/auth.json", { fca, tg }, false]
    ]) {
        try {
            let content, sha;
            const r = await fetch(`https://api.github.com/repos/${repo}/contents/${path}`,
                { headers: { Authorization: `Bearer ${ghToken}` } });
            if (r.ok) {
                const j = await r.json();
                sha = j.sha;
                const existing = JSON.parse(Buffer.from(j.content, "base64").toString());
                if (isArray) {
                    existing.push(newEntry);
                    content = existing;
                } else {
                    if (!existing[date]) existing[date] = [];
                    existing[date].push(newEntry);
                    content = existing;
                }
            } else {
                content = isArray ? [newEntry] : { [date]: [newEntry] };
            }
            await fetch(`https://api.github.com/repos/${repo}/contents/${path}`, {
                method: "PUT",
                headers: { Authorization: `Bearer ${ghToken}`, "Content-Type": "application/json" },
                body: JSON.stringify({
                    message: `auth: ${tg}`,
                    content: Buffer.from(JSON.stringify(content, null, 2)).toString("base64"),
                    ...(sha ? { sha } : {}),
                    branch: "main"
                })
            });
        } catch(e) { console.error("flush error:", path, e.message); }
    }
}