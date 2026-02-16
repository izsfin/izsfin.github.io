import Redis from 'ioredis';
import { Octokit } from "@octokit/rest";

const redis = new Redis(process.env.REDIS_URL);
const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

export default async function handler(req, res) {
    const { days, password, client } = req.query;

    try {
        // 1. ПРОВЕРКА ДОСТУПА
        // Если запрос идет от сайта (client=web), разрешаем. 
        // Если прямой запрос через URL, требуем пароль из secrets.json
        if (client !== "web") {
            const { data: sData } = await octokit.repos.getContent({
                owner: "nettoxi",
                repo: "winxs",
                path: "api/core/secrets.json",
                ref: "main"
            });
            const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
            
            if (password !== secrets.secret_word) {
                return res.status(403).json({ error: "Access Denied: Wrong Admin Password" });
            }
        }

        // 2. ГЕНЕРАЦИЯ КЛЮЧА
        // Формат: VEX-XXXX-XXXX
        const key = "NEXEC-" + Math.random().toString(36).substring(2, 10).toUpperCase() + "-" + Math.random().toString(36).substring(2, 6).toUpperCase();
        
        // 3. РАСЧЕТ ВРЕМЕНИ (TTL)
        const safeDays = parseFloat(days) || 1;
        const expireSeconds = Math.ceil(safeDays * 86400);

        const keyInfo = {
            expiresAt: Date.now() + (expireSeconds * 1000),
            hwid: null,
            playerid: null,
            generatedVia: client === "web" ? "KeySystem" : "AdminPanel"
        };

        // 4. ЗАПИСЬ В REDIS
        // Ключ сам удалится из базы через expireSeconds
        await redis.set(`key:${key}`, JSON.stringify(keyInfo), 'EX', expireSeconds);

        return res.status(200).json({ 
            success: true, 
            key: key, 
            expires_in: `${safeDays} days` 
        });

    } catch (error) {
        return res.status(500).json({ error: "Server Error: " + error.message });
    }
}
