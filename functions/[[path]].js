import { Octokit } from "@octokit/rest";

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const host = request.headers.get("host") || "";
    
    // В Cloudflare переменные берутся из env (не забудь добавить GITHUB_TOKEN в Dash)
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    
    let rawPath = url.pathname.replace(/^\/+/, "");
    const selectedLang = url.searchParams.get("lang") || "RU";
    const userAgent = request.headers.get("user-agent") || "";
    // CF предоставляет IP через специальный заголовок
    const ip = request.headers.get("cf-connecting-ip") || request.headers.get("x-forwarded-for") || "0.0.0.0";

    const OWNER = "phxmale";
    const REPO = "wexly";
    const MY_IP = "77.52.212.190";

    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || request.headers.get('vellote-access') === 'true';
    const isOwner = ip === MY_IP;

    // --- ФИЛЬТР БОТОВ ---
    const isBotCrawler = ua.includes("discordbot") || ua.includes("telegrambot") || ua.includes("twitterbot") || ua.includes("facebookexternalhit") || ua.includes("linkedinbot");
    if (isBotCrawler) return new Response("OK", { status: 200 });

    // --- DOCS ДОМЕН ---
    if (host.includes("vellote-docs")) {
        if (!rawPath || rawPath === "index") return serveDocsFallback(octokit, OWNER, REPO, "home.html", selectedLang);
        if (rawPath === "auth")               return serveDocsFallback(octokit, OWNER, REPO, "auth.html", selectedLang);
        if (rawPath === "create")             return serveDocsFallback(octokit, OWNER, REPO, "create.html", selectedLang);
        if (rawPath.startsWith("post"))       return serveDocsFallback(octokit, OWNER, REPO, "post.html", selectedLang);
        return serveDocsFallback(octokit, OWNER, REPO, "home.html", selectedLang);
    }

    // --- ОПРЕДЕЛЕНИЕ ВЕТКИ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    if (host.includes("vellote-testing"))  { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("vellote-api")) { codeBranch = "api"; }
    else if (host.includes("vellote-raw")) { codeBranch = "raw"; }
    else if (host.includes("vellote-cdn")) { codeBranch = "cdn"; }
    else if (host.includes("vellote"))     { codeBranch = "off"; }

    // --- ИСКЛЮЧЕНИЯ ПО ПУТИ ---
    if (rawPath === 'bio/phxmale')      return serveFallback(octokit, OWNER, REPO, 'bio/main.html', selectedLang);
    if (rawPath === "obfuscator")        return serveFallback(octokit, OWNER, REPO, "obfuscator.html", selectedLang);
    if (rawPath === "getkey")            return serveFallback(octokit, OWNER, REPO, "getkey.html", selectedLang);
    if (rawPath === "status")            return serveFallback(octokit, OWNER, REPO, "status.html", selectedLang);
    if (rawPath === "catalog")           return serveFallback(octokit, OWNER, REPO, "catalog.html", selectedLang);
    if (rawPath === "auth")              return serveFallback(octokit, OWNER, REPO, "authSS.html", selectedLang);
    if (rawPath === "auth/cmd")          return serveFallback(octokit, OWNER, REPO, "authCS.html", selectedLang);
    if (rawPath.startsWith("catalog/"))  return serveFallback(octokit, OWNER, REPO, "catalog-item.html", selectedLang);

    if (rawPath.startsWith("static/")) {
        if (!userAgent.includes("hux9z/software")) {
            return new Response(isRoblox ? "-- Vellote Error: Access Denied" : "Forbidden", { status: 403 });
        }
    }

    // --- API CATALOG ---
    if (rawPath === "api/catalog/info" || rawPath === "api/catalog/verified") {
        try {
            const fileName = rawPath === "api/catalog/info" ? "info.json" : "verified.json";
            const { data } = await octokit.repos.getContent({
                owner: OWNER, repo: REPO, path: "api/catalog/" + fileName, ref: "main"
            });
            const content = atob(data.content); // В браузерной среде Cloudflare используем atob вместо Buffer
            return new Response(content, {
                status: 200,
                headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
            });
        } catch(e) {
            return new Response(JSON.stringify({ error: "Not found", detail: e.message }), { 
                status: 404, headers: { "Content-Type": "application/json" } 
            });
        }
    }

    // --- СЕКРЕТЫ ---
    let secretWord = "vlt";
    let secretRules = [];
    let aliases = {};
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        const secrets = JSON.parse(atob(sData.content));
        secretWord = secrets.secret_word.toLowerCase();
        secretRules = secrets.secrets || [];
        aliases = secrets.aliases || {};
    } catch (e) {}

    let isSecretValid = isRoblox;
    let matchedRule = null;

    if (rawPath.includes("@")) {
        const parts = rawPath.split("@");
        const providedSecret = parts.pop().toLowerCase().trim();
        rawPath = parts.join("@");
        if (providedSecret === secretWord) isSecretValid = true;
        else matchedRule = secretRules.find(r => r.symbol.toLowerCase() === providedSecret) || null;
    }

    const cleanPath = rawPath.toLowerCase().trim();
    const domainKey = Object.keys(aliases).find(k => host.includes(k));
    if (domainKey && aliases[domainKey][cleanPath]) rawPath = aliases[domainKey][cleanPath];

    if (!rawPath || rawPath === "index") return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang);

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
        "lua": "text/plain", "luaz": "text/plain", "py": "text/x-python", "java": "text/x-java-source", 
        "c": "text/x-c", "cpp": "text/x-c++", 
        "cs": "text/plain", "go": "text/plain", "rs": "text/plain",
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
        "wasm": "application/wasm", "default": "application/octet-stream"
    };
try {
        const pathParts = rawPath.split('/').filter(p => p);
        const searchFileName = pathParts.pop().toLowerCase();
        const searchDir = pathParts.join('/').toLowerCase();

        const { data: items } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch
        });

        const target = Array.isArray(items) && items.find(i => {
            const n = i.name.toLowerCase();
            const nameWithoutExt = n.includes('.') ? n.split('.').slice(0, -1).join('.') : n;
            return i.type === 'file' && (n === searchFileName || nameWithoutExt === searchFileName);
        });

        if (!target) return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang);

        const ext = target.name.split('.').pop().toLowerCase();
        if ((["zip", "exe"].includes(ext)) && isRoblox) return new Response("-- Vellote Error: Access Denied", { status: 403 });

        if (!matchedRule && !isSecretValid && !isOwner) {
            await sendToLogger(ip, rawPath, host, userAgent, "🛡️ Access Blocked");
            return new Response(isRoblox ? "-- Vellote Error: Access Denied. Use @secret" : "Forbidden", { status: 403 });
        }

        if (!isOwner && !isRoblox) await sendToLogger(ip, target.name, host, userAgent, "✅ File Loaded");

        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        let content;
        if (fileData.content) {
            // Конвертируем base64 в бинарные данные для Response
            const binaryString = atob(fileData.content);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) bytes[i] = binaryString.charCodeAt(i);
            content = bytes;
        } else {
            const res = await fetch(fileData.download_url);
            content = await res.arrayBuffer();
        }

        const mime = mimeTypes[ext] || mimeTypes["default"];
        return new Response(content, {
            status: 200,
            headers: { 
                "Content-Type": mime, 
                "Access-Control-Allow-Origin": "*",
                "Content-Disposition": (["zip", "exe"].includes(ext)) ? `attachment; filename="${target.name}"` : 'inline'
            }
        });

    } catch (e) {
        return new Response(isRoblox ? "-- Vellote Error: " + e.message : "Internal Error", { status: 500 });
    }
}

async function serveFallback(octokit, owner, repo, file, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/html/${file}`, ref: "main" });
        const html = atob(fb.content).replace(/{{LANG}}/g, lang);
        return new Response(html, { status: 200, headers: { "Content-Type": "text/html" } });
    } catch { return new Response("Not Found", { status: 404 }); }
}

async function serveDocsFallback(octokit, owner, repo, file, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/docs/${file}`, ref: "main" });
        const html = atob(fb.content).replace(/{{LANG}}/g, lang);
        return new Response(html, { status: 200, headers: { "Content-Type": "text/html" } });
    } catch { return new Response("Not Found", { status: 404 }); }
}

async function sendToLogger(ip, path, domain, userAgent, status) {
    try {
        await fetch(`https://${domain}/functions/logger`, { // Обнови путь к логгеру если нужно
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ip, path, domain, userAgent, status })
        });
    } catch (e) {}
}