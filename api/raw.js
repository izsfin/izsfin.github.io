import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

// Хелпер для обновления файлов на GitHub
async function updateRepoFile(path, data, message) {
    const { data: currentFile } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path, ref: "main" });
    await octokit.repos.createOrUpdateFileContents({
        owner: OWNER, repo: REPO, path, message,
        content: Buffer.from(JSON.stringify(data, null, 2)).toString('base64'),
        sha: currentFile.sha,
        branch: "main"
    });
}

export default async function handler(req, res) {
    const { key, hwid, playerid } = req.query;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    if (!key || !hwid) return res.status(400).json({ error: "Missing key or hwid" });

    try {
        // 1. Читаем базы
        const kFile = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: "api/keys/keys.json", ref: "main" });
        const bFile = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: "api/keys/blacklist.json", ref: "main" });
        
        let keysData = JSON.parse(Buffer.from(kFile.data.content, 'base64').toString('utf-8'));
        let blacklist = JSON.parse(Buffer.from(bFile.data.content, 'base64').toString('utf-8'));

        // 2. Проверка бана
        const userBan = blacklist.banned[hwid];
        if (userBan && Date.now() < userBan.unbanAt) {
            return res.status(403).json({ status: "BANNED", until: new Date(userBan.unbanAt).toLocaleString() });
        }

        // 3. Валидация ключа
        const keyInfo = keysData.active_keys[key];
        if (!keyInfo) return res.status(404).json({ status: "INVALID" });

        // Проверка времени
        if (Date.now() > keyInfo.expiresAt) {
            delete keysData.active_keys[key];
            await updateRepoFile("api/keys/keys.json", keysData, `Key ${key} expired`);
            return res.status(401).json({ status: "EXPIRED" });
        }

        // 4. HWID логика
        if (!keyInfo.hwid) {
            // Первая привязка
            keyInfo.hwid = hwid;
            keyInfo.playerid = playerid;
            await updateRepoFile("api/keys/keys.json", keysData, `Linked key ${key} to HWID ${hwid}`);
            return res.status(200).json({ status: "OK", message: "Key linked" });
        } else if (keyInfo.hwid !== hwid) {
            // ПОПЫТКА КРАЖИ КЛЮЧА - Система банов
            const banLevel = (blacklist.banned[hwid]?.level || 0) + 1;
            const banDurations = [0, 900000, 3600000, 86400000, 259200000]; // 15м, 1ч, 1д, 3д в мс
            const unbanAt = Date.now() + (banDurations[banLevel] || 315360000000); // 5+ раз = пермач

            blacklist.banned[hwid] = {
                ip, playerid, level: banLevel, unbanAt, 
                reason: `HWID Mismatch (Key: ${key})`
            };
            
            await updateRepoFile("api/keys/blacklist.json", blacklist, `Banned HWID ${hwid} - Level ${banLevel}`);
            return res.status(403).json({ status: "BANNED", level: banLevel });
        }

        // Все успешно
        return res.status(200).json({ status: "OK", expires: keyInfo.expiresAt });

    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
}
