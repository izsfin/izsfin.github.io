import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const url = new URL(req.url, `https://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, "");
    const selectedLang = req.query.lang || "RU";
    const userAgent = req.headers['user-agent'] || "";
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    const MY_IP = "77.52.212.190";

    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || req.headers['winxs-access'] === 'true';
    const isOwner = ip === MY_IP;

    let codeBranch = "main";
    let fallbackFile = "main.html";
    if (host.includes("auth-winxs")) { codeBranch = "auth"; fallbackFile = "getkey.html"; }
    else if (host.includes("test-winxs")) { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("api-winxs")) { codeBranch = "api"; }
    else if (host.includes("raw-winxs")) { codeBranch = "raw"; }
    else if (host.includes("cdn-winxs")) { codeBranch = "cdn"; }
    else if (host.includes("offwinxs")) { codeBranch = "off"; }

    // --- ЗАГРУЗКА СЕКРЕТОВ ---
    let secretWord = "night";
    let secretRules = []; // [{ symbol, type, extensions }]
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        secretWord = secrets.secret_word.toLowerCase();
        secretRules = secrets.secrets || [];
    } catch (e) {}

    // --- ПАРСИНГ ПУТИ И СЕКРЕТА ---
    let isSecretValid = false;
    let matchedRule = null; // правило из JSON которое совпало с символом

    if (isRoblox) isSecretValid = true;

    if (rawPath.includes("@")) {
        const parts = rawPath.split("@");
        const providedSecret = parts.pop().toLowerCase().trim();
        rawPath = parts.join("@");

        if (providedSecret === secretWord) {
            isSecretValid = true;
        } else {
            // ищем правило по символу
            matchedRule = secretRules.find(r => r.symbol.toLowerCase() === providedSecret) || null;
        }
    }

    if (!rawPath || rawPath === "index") return serveFallback(res, fallbackFile, selectedLang);

    const mimeTypes = {
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif",
        "webp": "image/webp", "svg": "image/svg+xml", "ico": "image/x-icon",
        "lua": "text/plain", "js": "application/javascript", "json": "application/json",
        "css": "text/css", "html": "text/html", "txt": "text/plain",
        "zip": "application/zip", "rar": "application/vnd.rar", "7z": "application/x-7z-compressed",
        "tar": "application/x-tar", "gz": "application/gzip",
        "exe": "application/octet-stream", "bin": "application/octet-stream",
        "default": "application/octet-stream"
    };

    // расширения архивов и приложений берём из JSON если есть, иначе fallback
    const archiveRule = secretRules.find(r => r.type === "Archive");
    const archiveExts = archiveRule ? archiveRule.extensions : ["zip", "rar", "7z", "tar", "gz"];
    const appExts = ["exe", "msi", "dmg", "apk"];

    try {
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

        if (!target) {
            if (isRoblox) return res.status(404).send("-- Winxs Error: File not found");
            return serveFallback(res, fallbackFile, selectedLang);
        }

        const ext = target.name.split('.').pop().toLowerCase();
        const isArchive = archiveExts.includes(ext);
        const isApp = appExts.includes(ext);

        // --- Архивы и приложения — Roblox не получает ---
        if ((isArchive || isApp) && isRoblox) {
            return res.status(403).send("-- Winxs Error: Access Denied");
        }

        // --- Проверка секретного символа ---
        if (matchedRule) {
            // символ найден — проверяем подходит ли расширение файла под правило
            if (!matchedRule.extensions.includes(ext)) {
                if (isRoblox) return res.status(403).send("-- Winxs Error: Wrong file type for this secret");
                return serveFallback(res, fallbackFile, selectedLang);
            }
            // всё ок, даём доступ
        } else if (!isSecretValid) {
            // нет ни секретного слова ни правила
            if (!isOwner) {
                await sendToLogger(ip, rawPath, host, userAgent, "🛡️ Access Blocked");
                if (isRoblox) return res.status(403).send("-- Winxs Error: Access Denied");
                return serveFallback(res, fallbackFile, selectedLang);
            }
        }

        // --- ЛОГГИРОВАНИЕ ---
        if (!isOwner && !isRoblox) {
            await sendToLogger(ip, target.name, host, userAgent, "✅ File Loaded");
        }

        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        const content = Buffer.from(fileData.content, 'base64');
        const mime = mimeTypes[ext] || mimeTypes["default"];

        // --- Архивы/приложения — принудительное скачивание для людей ---
        if ((isArchive || isApp) && !isRoblox) {
            res.setHeader('Content-Disposition', `attachment; filename="${target.name}"`);
        }

        res.setHeader('Content-Type', mime);
        res.setHeader('Access-Control-Allow-Origin', '*');

        const textTypes = ["text/plain", "application/javascript", "text/css", "text/html", "application/json", "text/yaml", "text/markdown", "application/xml"];

        return res.status(200).send(
            textTypes.includes(mime) ? content.toString('utf-8') : content
        );

    } catch (e) {
        if (isRoblox) return res.status(500).send("-- Winxs Error: Server Exception");
        return serveFallback(res, fallbackFile, selectedLang);
    }
}

async function serveFallback(res, file, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner: "nettoxi", repo: "winxs", path: `site/html/${file}`, ref: "main" });
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
