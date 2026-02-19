import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const url = new URL(req.url, `https://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, "");
    const selectedLang = req.query.lang || "RU";
    const userAgent = req.headers['user-agent'] || "Unknown";
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    // --- 1. ОПРЕДЕЛЕНИЕ ВЕТКИ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    if (host.includes("auth-winxs")) { codeBranch = "auth"; fallbackFile = "getkey.html"; }
    else if (host.includes("test-winxs")) { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("api-winxs")) { codeBranch = "api"; }
    else if (host.includes("raw-winxs")) { codeBranch = "raw"; }
    else if (host.includes("cdn-winxs")) { codeBranch = "cdn"; }

    // --- 2. ПОЛУЧЕНИЕ СЕКРЕТКИ (Night) ---
    let secretWord = "night";
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        secretWord = secrets.secret_word.toLowerCase();
    } catch (e) { console.error("Secrets fetch error, using 'night'"); }

    // --- 3. ЛОГИКА ДОСТУПА ---
    let isSecretValid = false;
    let isMediaSecret = false;

    // Белый список IP и Roblox User-Agent
    const isRoblox = userAgent.toLowerCase().includes("roblox");
    const isOwnerIP = ip === "77.52.212.190";

    if (isRoblox || isOwnerIP) {
        isSecretValid = true;
    }

    // Обработка @ ключей
    if (rawPath.includes("@")) {
        const parts = rawPath.split("@");
        const providedSecret = parts.pop().toLowerCase().trim();
        rawPath = parts.join("@");

        if (providedSecret === secretWord) {
            isSecretValid = true;
        } else if (providedSecret === "bg") {
            isMediaSecret = true;
        }
    }

    if (!rawPath || rawPath === "index") return serveFallback(res, fallbackFile, selectedLang);

    try {
        // --- 4. ПОИСК ФАЙЛА ---
        const pathParts = rawPath.split('/').filter(p => p);
        const searchFileName = pathParts.pop().toLowerCase();
        const searchDir = pathParts.join('/');

        const { data: items } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch
        });

        const target = Array.isArray(items) && items.find(i => {
            const n = i.name.toLowerCase();
            return i.type === 'file' && (n === searchFileName || n.split('.')[0] === searchFileName);
        });

        if (!target) return serveFallback(res, fallbackFile, selectedLang);

        const ext = target.name.split('.').pop().toLowerCase();
        const isImage = ['png', 'jpg', 'jpeg', 'ico', 'svg', 'webp', 'gif'].includes(ext);

        // --- 5. ПРОВЕРКА ПРАВ НА КОНКРЕТНЫЙ ТИП ---
        // Если зашли через @bg, но это не картинка — отказ
        if (isMediaSecret && !isImage) {
            return serveFallback(res, fallbackFile, selectedLang);
        }

        // Если файл найден, но нет прав (не секрет, не Roblox, не Owner IP)
        if (!isSecretValid && !isMediaSecret) {
            await sendToLogger(ip, rawPath, host, userAgent, "🛡️ Access Blocked");
            return serveFallback(res, fallbackFile, selectedLang);
        }

        // --- 6. ВЫДАЧА ---
        await sendToLogger(ip, target.name, host, userAgent, "✅ Delivered");

        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        const content = Buffer.from(fileData.content, 'base64');
        
        // Маппинг MIME-типов (сокращено для примера, используй свой полный список)
        const mimeTypes = { 
            "lua": "text/plain", "js": "application/javascript", 
            "png": "image/png", "jpg": "image/jpeg", "svg": "image/svg+xml",
            "ico": "image/x-icon", "default": "application/octet-stream"
        };

        res.setHeader('Content-Type', mimeTypes[ext] || mimeTypes["default"]);
        res.setHeader('Access-Control-Allow-Origin', '*');
        
        return res.status(200).send(
            ['png', 'jpg', 'jpeg', 'gif', 'webp', 'ico', 'zip'].includes(ext) 
            ? content : content.toString('utf-8')
        );

    } catch (e) {
        return serveFallback(res, fallbackFile, selectedLang);
    }
}

async function serveFallback(res, file, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({
            owner: "nettoxi", repo: "winxs", path: `site/html/${file}`, ref: "main"
        });
        const html = Buffer.from(fb.content, 'base64').toString('utf-8');
        res.setHeader('Content-Type', 'text/html');
        return res.status(200).send(html.replace(/{{LANG}}/g, lang));
    } catch { return res.status(404).send("Not Found"); }
}

async function sendToLogger(ip, path, domain, userAgent, status) {
    try {
        await fetch(`https://${domain}/api/logger`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ip, path, domain, userAgent, status })
        });
    } catch (e) {}
}
