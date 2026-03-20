import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "varmoxd";
const REPO = "wexly";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const url = new URL(req.url, `https://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, "");
    const selectedLang = req.query.lang || "RU";
    const userAgent = req.headers['user-agent'] || "";
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    const MY_IP = "77.52.212.190";

    // --- 1. ОПРЕДЕЛЕНИЕ КЛИЕНТА ---
    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || req.headers['Nekoq-access'] === 'true';
    const isOwner = ip === MY_IP;

    // --- 2. ФИЛЬТР БОТОВ ---
    const isBotCrawler = ua.includes("discordbot") || ua.includes("telegrambot") || ua.includes("twitterbot") || ua.includes("facebookexternalhit") || ua.includes("linkedinbot");
    if (isBotCrawler) return res.status(200).send("OK");

    // --- 3. ОПРЕДЕЛЕНИЕ ВЕТКИ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    if (host.includes("nekoq-testing"))  { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("nekoq-api")) { codeBranch = "api"; }
    else if (host.includes("nekoq-raw")) { codeBranch = "raw"; }
    else if (host.includes("nekoq-cdn")) { codeBranch = "cdn"; }
    else if (host.includes("nekoq"))     { codeBranch = "off"; }

    // --- 3.1. ИСКЛЮЧЕНИЯ ПО ПУТИ ---
    if (rawPath === "obfuscator") return serveFallback(res, "obfuscator.html", selectedLang);
    if (rawPath === "getkey")     return serveFallback(res, "getkey.html", selectedLang);
    if (rawPath === "api/gen") { /* pass through to Vercel function directly */ }
    if (rawPath === "status")     return serveFallback(res, "status.html", selectedLang);
    if (rawPath === "catalog")    return serveFallback(res, "catalog.html", selectedLang);
    if (rawPath === "auth")       return serveFallback(res, "authSS.html", selectedLang);
    if (rawPath === "auth/cmd")   return serveFallback(res, "authCS.html", selectedLang);
    if (rawPath.startsWith("catalog/")) return serveFallback(res, "catalog-item.html", selectedLang);
    
    if (rawPath.startsWith("ximeax/")) {
    const xmsUA = req.headers['user-agent'] || "";
    if (!xmsUA.includes("ximeax/software")) {
        if (isRoblox) return res.status(403).send("-- Nekoq Error: Access Denied");
        return res.status(403).send("Forbidden");
      }
    }
    if (rawPath === "api/catalog/info" || rawPath === "api/catalog/verified") {
        try {
            const fileName = rawPath === "api/catalog/info" ? "info.json" : "verified.json";
            const { data } = await octokit.repos.getContent({
                owner: OWNER, repo: REPO,
                path: "api/catalog/" + fileName, ref: "main"
            });
            const content = Buffer.from(data.content, "base64").toString("utf-8");
            res.setHeader("Content-Type", "application/json");
            res.setHeader("Access-Control-Allow-Origin", "*");
            return res.status(200).send(content);
        } catch(e) {
            return res.status(404).json({ error: "Not found", detail: e.message });
        }
    }

    // --- 4. STATUS ДОМЕН ---
    if (host.includes("Nekoq-status")) {
        return serveFallback(res, "status.html", selectedLang);
    }

    // --- 5. ЗАГРУЗКА СЕКРЕТОВ ---
    let secretWord = "sosi";
    let secretRules = [];
    let aliases = {};
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        secretWord = secrets.secret_word.toLowerCase();
        secretRules = secrets.secrets || [];
        aliases = secrets.aliases || {};
    } catch (e) {}

    // --- 6. ПАРСИНГ СЕКРЕТА ---
    let isSecretValid = false;
    let matchedRule = null;

    if (isRoblox) isSecretValid = true;

    if (rawPath.includes("@")) {
        const parts = rawPath.split("@");
        const providedSecret = parts.pop().toLowerCase().trim();
        rawPath = parts.join("@");

        if (providedSecret === secretWord) {
            isSecretValid = true;
        } else {
            matchedRule = secretRules.find(r => r.symbol.toLowerCase() === providedSecret) || null;
        }
    }

    // --- 7. АЛИАСЫ ---
    const cleanPath = rawPath.toLowerCase().trim();
    const domainKey = Object.keys(aliases).find(k => host.includes(k));
    if (domainKey && aliases[domainKey][cleanPath]) {
        rawPath = aliases[domainKey][cleanPath];
    }

    if (!rawPath || rawPath === "index") return serveFallback(res, fallbackFile, selectedLang);

    // --- 8. MIME ТИПЫ ---
    const mimeTypes = {
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "jpe": "image/jpeg",
        "gif": "image/gif", "bmp": "image/bmp", "webp": "image/webp", "avif": "image/avif",
        "apng": "image/apng", "svg": "image/svg+xml", "svgz": "image/svg+xml", "ico": "image/x-icon",
        "tif": "image/tiff", "tiff": "image/tiff", "heic": "image/heic", "heif": "image/heif",
        "html": "text/html", "htm": "text/html", "css": "text/css", "js": "application/javascript",
        "mjs": "application/javascript", "ts": "application/typescript",
        "txt": "text/plain", "log": "text/plain", "ini": "text/plain", "cfg": "text/plain",
        "md": "text/markdown", "csv": "text/csv", "json": "application/json", "xml": "application/xml",
        "yaml": "text/yaml", "yml": "text/yaml",
        "lua": "text/plain", "py": "text/x-python", "java": "text/x-java-source", "c": "text/x-c",
        "cpp": "text/x-c++", "cs": "text/plain", "go": "text/plain", "rs": "text/plain",
        "php": "application/x-httpd-php", "rb": "text/plain", "sh": "application/x-sh",
        "bat": "application/x-msdownload", "ps1": "text/plain",
        "mp3": "audio/mpeg", "wav": "audio/wav", "ogg": "audio/ogg", "aac": "audio/aac",
        "m4a": "audio/mp4", "flac": "audio/flac",
        "mp4": "video/mp4", "webm": "video/webm", "mov": "video/quicktime", "avi": "video/x-msvideo",
        "mkv": "video/x-matroska",
        "ttf": "font/ttf", "otf": "font/otf", "woff": "font/woff", "woff2": "font/woff2",
        "zip": "application/zip", "rar": "application/vnd.rar", "7z": "application/x-7z-compressed",
        "tar": "application/x-tar", "gz": "application/gzip", "bz2": "application/x-bzip2",
        "xz": "application/x-xz", "iso": "application/x-iso9660-image",
        "pdf": "application/pdf", "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "exe": "application/octet-stream", "msi": "application/octet-stream", "dll": "application/octet-stream",
        "bin": "application/octet-stream", "apk": "application/vnd.android.package-archive",
        "wasm": "application/wasm",
        "default": "application/octet-stream"
    };

    const archiveRule = secretRules.find(r => r.type === "Archive");
    const archiveExts = archiveRule ? archiveRule.extensions : ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "iso"];
    const appExts = ["exe", "msi", "dmg", "apk"];

    try {
        const pathParts = rawPath.split('/').filter(p => p);
        const searchFileName = pathParts.pop().toLowerCase();
        const searchDir = pathParts.join('/').toLowerCase();

        console.log(`Trying: Branch=${codeBranch}, Dir=${searchDir}, File=${searchFileName}`);

        const { data: items } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch
        });

        const target = Array.isArray(items) && items.find(i => {
            const n = i.name.toLowerCase();
            const nameWithoutExt = n.includes('.') ? n.split('.').slice(0, -1).join('.') : n;
            return i.type === 'file' && (n === searchFileName || nameWithoutExt === searchFileName);
        });

        if (!target) {
            if (isRoblox) return res.status(404).send("-- Nekoq Error: File not found");
            return serveFallback(res, fallbackFile, selectedLang);
        }

        const ext = target.name.split('.').pop().toLowerCase();
        const isArchive = archiveExts.includes(ext);
        const isApp = appExts.includes(ext);

        if ((isArchive || isApp) && isRoblox) {
            return res.status(403).send("-- Nekoq Error: Access Denied");
        }

        // --- 9. ПРОВЕРКА ДОСТУПА ---
        if (matchedRule) {
            if (!matchedRule.extensions.includes(ext)) {
                if (isRoblox) return res.status(403).send("-- Nekoq Error: Wrong file type for this secret");
                return serveFallback(res, fallbackFile, selectedLang);
            }
        } else if (!isSecretValid) {
            if (!isOwner) {
                await sendToLogger(ip, rawPath, host, userAgent, "🛡️ Access Blocked");
                if (isRoblox) return res.status(403).send("-- Nekoq Error: Access Denied. Use @secret");
                return serveFallback(res, fallbackFile, selectedLang);
            }
        }

        // --- 10. ЛОГГИРОВАНИЕ ---
        if (!isOwner && !isRoblox) {
            await sendToLogger(ip, target.name, host, userAgent, "✅ File Loaded");
        }

        // --- 11. ПОЛУЧЕНИЕ ФАЙЛА ---
        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        let content;
        if (fileData.content) {
            content = Buffer.from(fileData.content, 'base64');
        } else if (fileData.download_url) {
            const response = await fetch(fileData.download_url);
            const arrayBuffer = await response.arrayBuffer();
            content = Buffer.from(arrayBuffer);
        }

        const mime = mimeTypes[ext] || mimeTypes["default"];

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
        console.error("Fetch Error:", e.message);
        if (isRoblox) return res.status(500).send("-- Nekoq Error: " + e.message);
        return serveFallback(res, fallbackFile, selectedLang);
    }
}

async function serveFallback(res, file, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: `site/html/${file}`, ref: "main"
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