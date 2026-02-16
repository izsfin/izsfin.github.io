import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);
const MY_IP = "77.52.212.190";

export default async function handler(req, res) {
    const { key, hwid, playerid } = req.query;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const host = req.headers.host;
    const userAgent = req.headers['user-agent'] || "Unknown";

    if (!key || !hwid) return res.status(400).json({ status: "ERROR", message: "Missing params" });

    // Функция отправки в твой логгер
    const sendLog = async (status, level = 0) => {
        if (ip === MY_IP) return;
        try {
            await fetch(`https://${host}/api/logger`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    ip,
                    path: `CheckKey:${key}`,
                    domain: host,
                    userAgent,
                    status: `${status} (LVL: ${level})`
                })
            });
        } catch (e) {}
    };

    try {
        // 1. ПРОВЕРКА НА БАН
        const isBanned = await redis.get(`ban:${hwid}`);
        if (isBanned) {
            const banInfo = JSON.parse(isBanned);
            if (Date.now() < banInfo.unbanAt) {
                return res.status(403).json({ 
                    status: "BANNED", 
                    reason: banInfo.reason,
                    until: new Date(banInfo.unbanAt).toLocaleString('ru-RU')
                });
            }
        }

        // 2. ПОЛУЧАЕМ КЛЮЧ
        const keyData = await redis.get(`key:${key}`);
        if (!keyData) {
            await sendLog("INVALID_KEY_ATTEMPT");
            return res.status(404).json({ status: "INVALID" });
        }

        let info = JSON.parse(keyData);

        // 3. ПРИВЯЗКА HWID (Если ключ новый)
        if (!info.hwid) {
            info.hwid = hwid;
            info.playerid = playerid || "Unknown";
            info.activatedAt = Date.now();
            
            const remainingTTL = await redis.ttl(`key:${key}`);
            await redis.set(`key:${key}`, JSON.stringify(info), 'EX', remainingTTL > 0 ? remainingTTL : 86400);
            
            await sendLog("KEY_ACTIVATED");
            return res.status(200).json({ status: "OK", message: "Activated" });
        }

        // 4. ПРОВЕРКА СОВПАДЕНИЯ HWID
        if (info.hwid !== hwid) {
            // Прогрессивные баны: 15м, 1ч, 1д, 7д, Пермач
            const banLvl = await redis.incr(`ban_lvl:${hwid}`);
            const durations = [0, 900000, 3600000, 86400000, 604800000]; 
            const duration = durations[banLvl] || 315360000000;

            const banObj = {
                unbanAt: Date.now() + duration,
                reason: `HWID Mismatch. Target Key: ${key}`,
                level: banLvl
            };

            await redis.set(`ban:${hwid}`, JSON.stringify(banObj), 'EX', Math.ceil(duration / 1000));
            await sendLog("HWID_THEFT_DETECTED", banLvl);
            
            return res.status(403).json({ status: "BANNED", level: banLvl });
        }

        // Успешный вход
        return res.status(200).json({ status: "OK" });

    } catch (error) {
        return res.status(500).json({ status: "ERROR", message: error.message });
    }
}
