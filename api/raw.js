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
    const acceptHeader = req.headers['accept'] || "";
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    const MY_IP = "77.52.212.190";
    
    // --- 1. ЛОГИКА ОПРЕДЕЛЕНИЯ КЛИЕНТА ---
    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || req.headers['winxs-access'] === 'true';
    const isOwner = ip === MY_IP;

    // --- 2. ОПРЕДЕЛЕНИЕ ВЕТКИ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    if (host.includes("auth-winxs")) { codeBranch = "auth"; fallbackFile = "getkey.html"; }
    else if (host.includes("test-winxs")) { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("api-winxs")) { codeBranch = "api"; }
    else if (host.includes("raw-winxs")) { codeBranch = "raw"; }
    else if (host.includes("cdn-winxs")) { codeBranch = "cdn"; }
    else if (host.includes("offwinxs")) { codeBranch = "off"; }

    // --- 3. ПОЛУЧЕНИЕ СЕКРЕТКИ ---
    let secretWord = "night";
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        secretWord = secrets.secret_word.toLowerCase();
    } catch (e) {}

    // --- 4. ПРОВЕРКА КЛЮЧЕЙ ---
    let isSecretValid = false;
    let isMediaSecret = false;

    if (isRoblox) isSecretValid = true;

    if (rawPath.includes("@")) {
        const parts = rawPath.split("@");
        const providedSecret = parts.pop().toLowerCase().trim();
        rawPath = parts.join("@");

        if (providedSecret === secretWord) isSecretValid = true;
        else if (providedSecret === "bg") isMediaSecret = true;
    }

    if (!rawPath || rawPath === "index") return serveFallback(res, fallbackFile, selectedLang);

    // --- 5. СПИСОК MIME-ТИПОВ ---
    const mimeTypes = {
        // IMAGES
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "jpe": "image/jpeg",
        "gif": "image/gif", "bmp": "image/bmp", "webp": "image/webp", "avif": "image/avif",
        "apng": "image/apng", "svg": "image/svg+xml", "svgz": "image/svg+xml", "ico": "image/x-icon",
        "tif": "image/tiff", "tiff": "image/tiff", "psd": "image/vnd.adobe.photoshop",
        "heic": "image/heic", "heif": "image/heif",
        // WEB
        "html": "text/html", "htm": "text/html", "shtml": "text/html", "xhtml": "application/xhtml+xml",
        "css": "text/css", "js": "application/javascript", "mjs": "application/javascript",
        "cjs": "application/javascript", "ts": "application/typescript", "tsx": "application/typescript",
        // TEXT
        "txt": "text/plain", "log": "text/plain", "ini": "text/plain", "cfg": "text/plain",
        "conf": "text/plain", "md": "text/markdown", "markdown": "text/markdown", "csv": "text/csv",
        "tsv": "text/tab-separated-values",
        // DATA
        "json": "application/json", "map": "application/json", "xml": "application/xml",
        "xsl": "application/xml", "yaml": "text/yaml", "yml": "text/yaml",
        // PROGRAMMING
        "lua": "text/plain", "py": "text/x-python", "java": "text/x-java-source", "c": "text/x-c",
        "cpp": "text/x-c++", "h": "text/x-c", "hpp": "text/x-c++", "cs": "text/plain",
        "go": "text/plain", "rs": "text/plain", "php": "application/x-httpd-php", "rb": "text/plain",
        "swift": "text/plain", "kt": "text/plain", "kts": "text/plain", "sh": "application/x-sh",
        "bash": "application/x-sh", "zsh": "application/x-sh", "bat": "application/x-msdownload", "ps1": "text/plain",
        // AUDIO
        "mp3": "audio/mpeg", "wav": "audio/wav", "ogg": "audio/ogg", "oga": "audio/ogg",
        "opus": "audio/opus", "aac": "audio/aac", "m4a": "audio/mp4", "flac": "audio/flac",
        "mid": "audio/midi", "midi": "audio/midi",
        // VIDEO
        "mp4": "video/mp4", "m4v": "video/mp4", "webm": "video/webm", "mov": "video/quicktime",
        "avi": "video/x-msvideo", "wmv": "video/x-ms-wmv", "mkv": "video/x-matroska", "flv": "video/x-flv",
        "3gp": "video/3gpp", "3g2": "video/3gpp2",
        // FONTS
        "ttf": "font/ttf", "otf": "font/otf", "woff": "font/woff", "woff2": "font/woff2", "eot": "application/vnd.ms-fontobject",
        // ARCHIVES
        "zip": "application/zip", "rar": "application/vnd.rar", "7z": "application/x-7z-compressed",
        "tar": "application/x-tar", "gz": "application/gzip", "bz2": "application/x-bzip2",
        "xz": "application/x-xz", "iso": "application/x-iso9660-image",
        // DOCUMENTS
        "pdf": "application/pdf", "doc": "application/msword", "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls": "application/vnd.ms-excel", "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "ppt": "application/vnd.ms-powerpoint", "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "odt": "application/vnd.oasis.opendocument.text", "ods": "application/vnd.oasis.opendocument.spreadsheet", "odp": "application/vnd.oasis.opendocument.presentation",
        // BINARY
        "exe": "application/octet-stream", "msi": "application/octet-stream", "dll": "application/octet-stream",
        "bin": "application/octet-stream", "apk": "application/vnd.android.package-archive",
        "deb": "application/vnd.debian.binary-package", "rpm": "application/x-rpm",
        // OTHER
        "wasm": "application/wasm", "torrent": "application/x-bittorrent", "pem": "application/x-pem-file",
        "crt": "application/x-x509-ca-cert", "cer": "application/pkix-cert", "key": "application/octet-stream",
        "default": "application/octet-stream"
    };

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
        const isImage = ['png', 'jpg', 'jpeg', 'ico', 'svg', 'webp', 'gif'].includes(ext);

        // --- 6. УСЛОВИЯ ДОСТУПА ---
        if (isMediaSecret && !isImage) {
            if (isRoblox) return res.status(403).send("-- Winxs Error: Media Only Secret");
            return serveFallback(res, fallbackFile, selectedLang);
        }

        if (!isSecretValid && !isMediaSecret) {
            if (!isOwner && !isRoblox) {
                await sendToLogger(ip, rawPath, host, userAgent, "🛡️ Access Blocked");
            }
            if (isRoblox) return res.status(403).send("-- Winxs Error: Access Denied. Use @secret");
            return serveFallback(res, fallbackFile, selectedLang);
        }

        // --- 7. ВЫДАЧА ФАЙЛА ---
        if (!isOwner && !isRoblox) {
            await sendToLogger(ip, target.name, host, userAgent, "✅ Script Loaded");
        }

        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        const content = Buffer.from(fileData.content, 'base64');
        const mime = mimeTypes[ext] || mimeTypes["default"];

        // Если это ZIP/EXE и запрос с ключом из браузера - включаем скачивание
        const forceDownload = ['zip', 'rar', '7z', 'exe', 'msi', 'bin', 'apk'].includes(ext);
        if (forceDownload && !isRoblox && isSecretValid) {
            res.setHeader('Content-Disposition', `attachment; filename="${target.name}"`);
        }

        res.setHeader('Content-Type', mime);
        res.setHeader('Access-Control-Allow-Origin', '*');

        // Список текстовых типов для корректной кодировки
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
