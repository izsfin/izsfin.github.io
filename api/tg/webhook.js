import Redis from "ioredis";
const redis = new Redis(process.env.REDIS_URL);

async function sendTG(botToken, chatId, text) {
    await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ chat_id: chatId, text, parse_mode: "Markdown" })
    });
}

export default async function handler(req, res) {
    if (req.method !== "POST") return res.status(405).end();
    const botToken = process.env.TG_BOT_TOKEN;
    const update   = req.body;
    res.status(200).end();

    if (!update.message) return;
    const msg      = update.message;
    const chatId   = msg.chat.id;
    const username = (msg.from?.username || "").toLowerCase();
    const text     = (msg.text || "").trim();

    // Store chat_id by username
    if (username) await redis.set(`tg:chatid:${username}`, chatId.toString());

    // /start
    if (text === "/start") {
        await sendTG(botToken, chatId,
            `👋 Hello @${username}!\n\nWelcome to *Ethereos Auth Bot*.\n\nTo authorize your device, go to:\nhttps://ethereos.vercel.app/auth\n\nThen send your auth code here.`);
        return;
    }

    // User sends auth code (6-9 chars, uppercase)
    if (/^[A-Z2-9]{6,9}$/.test(text)) {
        const code = text;
        await sendTG(botToken, chatId, `🔍 Checking code \`${code}\`...`);

        try {
            const r = await fetch(`${process.env.VERCEL_URL || "https://ethereos.vercel.app"}/api/hwid/auth/v1/bot-confirm`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ code, tg: username })
            });
            const data = await r.json();

            if (data.ok) {
                await sendTG(botToken, chatId,
                    `✅ *Successfully authorized!*\n\nFCA: \`${data.fca}\`\n\nSave this code for fast login on any device.`);
            } else {
                await sendTG(botToken, chatId,
                    `❌ Code not found or expired.\n\nGet a new one at: https://ethereos.vercel.app/auth`);
            }
        } catch(e) {
            await sendTG(botToken, chatId, `⚠️ Server error. Try again later.`);
        }
        return;
    }

    // Unknown
    await sendTG(botToken, chatId, `❓ Send your auth code from the site, or type /start for help.`);
}