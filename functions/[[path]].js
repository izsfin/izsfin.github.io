import { Octokit } from "@octokit/rest";

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const host = request.headers.get("host") || "";
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    
    let rawPath = url.pathname.replace(/^\/+/, "");
    const selectedLang = url.searchParams.get("lang") || "RU";
    const userAgent = request.headers.get("user-agent") || "";
    const ip = request.headers.get("cf-connecting-ip") || request.headers.get("x-forwarded-for") || "0.0.0.0";

    const OWNER = "phxmale";
    const REPO = "wexly";
    const MY_IP = "77.52.212.190";

    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || request.headers.get('vellote-access') === 'true';
    const isOwner = ip === MY_IP;

    // --- ФИЛЬТР БОТОВ ---
    if (ua.includes("discordbot") || ua.includes("telegrambot") || ua.includes("twitterbot")) {
        return new Response("OK", { status: 200 });
    }

    // --- ОПРЕДЕЛЕНИЕ ВЕТКИ И РОУТИНГ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";

    if (rawPath.startsWith(".cdn/")) { codeBranch = "cdn"; rawPath = rawPath.replace(".cdn/", ""); }
    else if (rawPath.startsWith(".api/")) { codeBranch = "api"; rawPath = rawPath.replace(".api/", ""); }
    else if (rawPath.startsWith(".testing/")) { codeBranch = "test"; fallbackFile = "test.html"; rawPath = rawPath.replace(".testing/", ""); }
    else if (rawPath.startsWith(".raw/")) { codeBranch = "raw"; rawPath = rawPath.replace(".raw/", ""); }

    // --- DOCS ЛОГИКА ---
    if (host.includes("vellote-docs") || rawPath.startsWith(".docs/")) {
        if (rawPath.startsWith(".docs/")) rawPath = rawPath.replace(".docs/", "");
        const docFile = (!rawPath || rawPath === "index") ? "home.html" : (rawPath.endsWith(".html") ? rawPath : `${rawPath}.html`);
        return serveDocsFallback(octokit, OWNER, REPO, docFile, selectedLang);
    }

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

    // --- ПРОДОЛЖЕНИЕ ПОСЛЕ MIME TYPES (V3 SS/FF EDITION) ---
    try {
        let gitHubPath = "";
        let fileName = "";
        const pathParts = rawPath.split('/').filter(p => p);
        
        // 1. ПОЛУЧАЕМ ПРЕФИКС (v3) ИЗ ss.txt
        const ssRes = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "functions/ver/ss.txt", ref: "main" 
        });
        const currentV = atob(ssRes.data.content).trim(); 

        // 2. РОУТИНГ V3
        if (rawPath.startsWith(`${currentV}/ff/`)) {
            // v3/ff/raw.js -> functions/raw.js
            fileName = pathParts[pathParts.length - 1].toLowerCase();
            const subDirs = pathParts.slice(2, -1).join('/');
            gitHubPath = `functions${subDirs ? '/' + subDirs : ''}`;
            
        } else if (rawPath.startsWith(`${currentV}/ss/`)) {
            // v3/ss/css/tailwind.css -> site/html/css/tailwind.css
            const cleanPath = rawPath.replace(`${currentV}/ss/`, "");
            const parts = cleanPath.split('/').filter(p => p);
            fileName = parts.pop().toLowerCase();
            gitHubPath = "site/html/" + parts.join('/');
            
        } else {
            // ОБЫЧНЫЕ ПУТИ И ИСКЛЮЧЕНИЯ
            const routes = {
                "bio/phxmale": "bio/main.html", "obfuscator": "obfuscator.html",
                "getkey": "getkey.html", "status": "status.html", "catalog": "catalog.html",
                "auth": "authSS.html", "auth/cmd": "authCS.html"
            };

            if (routes[rawPath]) return serveFallback(octokit, OWNER, REPO, routes[rawPath], selectedLang);
            if (rawPath.startsWith("catalog/")) return serveFallback(octokit, OWNER, REPO, "catalog-item.html", selectedLang);
            
            if (!rawPath || rawPath === "index") return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang);

            // Если не роут, значит ищем файл в site/html/
            fileName = pathParts.length > 0 ? pathParts.pop().toLowerCase() : "index.html";
            gitHubPath = "site/html/" + pathParts.slice(0, -1).join('/');
        }

        gitHubPath = gitHubPath.replace(/\/$/, "");

        // 3. ПОИСК И ВЫДАЧА
        const { data: items } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: gitHubPath, ref: codeBranch
        });

        const target = Array.isArray(items) && items.find(i => i.name.toLowerCase() === fileName);
        if (!target) return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang);

        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        let body;
        if (fileData.content) {
            const binary = atob(fileData.content);
            const bytes = new Uint8Array(binary.length);
            for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
            body = bytes;
        } else {
            const res = await fetch(fileData.download_url);
            body = await res.arrayBuffer();
        }

        const ext = fileName.split('.').pop().toLowerCase();
        const mime = mimeTypes[ext] || mimeTypes["default"];
        
        return new Response(body, {
            status: 200,
            headers: {
                "Content-Type": mime + (mime.startsWith("text/") ? "; charset=UTF-8" : ""),
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "public, max-age=3600"
            }
        });

    } catch (e) {
        return new Response(`Vellote Error: ${e.message}`, { status: 500 });
    }
}

// --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

async function serveFallback(octokit, owner, repo, path, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/html/${path}`, ref: "main" });
        const html = atob(fb.content).replace(/{{LANG}}/g, lang);
        return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=UTF-8" } });
    } catch {
        return new Response("Not Found", { status: 404 });
    }
}

async function serveDocsFallback(octokit, owner, repo, path, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/docs/${path}`, ref: "main" });
        const html = atob(fb.content).replace(/{{LANG}}/g, lang);
        return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=UTF-8" } });
    } catch {
        return new Response("Docs Not Found", { status: 404 });
    }
}

async function sendToLogger(ip, path, domain, userAgent, status) {
    try {
        await fetch(`https://${domain}/logger`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ip, path, domain, userAgent, status })
        });
    } catch (e) {}
}