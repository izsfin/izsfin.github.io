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
    const REPO = "aqusu.x";
    const MY_IP = "77.52.212.190";
    
    // Объявляем здесь, чтобы переменная была доступна везде в onRequest
    let fallbackFile = "main.html"; 
    let codeBranch = "main";
    let isBranchOverride = false;

    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || request.headers.get('vellote-access') === 'true';
    const isOwner = ip === MY_IP;

    // --- ФИЛЬТР БОТОВ ---
    if (ua.includes("discordbot") || ua.includes("telegrambot") || ua.includes("twitterbot")) {
        return new Response("OK", { status: 200 });
    }
    // Вставить после объявления переменных, перед блоком if (rawPath.startsWith(".cdn/"))
    if (host.includes("cdn-misslua")) {
        codeBranch = "cdn";
        isBranchOverride = true;
    } else if (host.includes("api-misslua")) {
        codeBranch = "api";
        isBranchOverride = true;
    } else if (host.includes("raw-misslua")) {
        codeBranch = "raw";
        isBranchOverride = true;
    }
    if (rawPath.startsWith(".cdn/")) { 
        codeBranch = "cdn"; 
        rawPath = rawPath.replace(".cdn/", ""); 
        isBranchOverride = true; 
    }
    else if (rawPath.startsWith(".api/")) { 
        codeBranch = "api"; 
        rawPath = rawPath.replace(".api/", ""); 
        isBranchOverride = true; 
    }
    else if (rawPath.startsWith(".testing/")) { 
        codeBranch = "test"; 
        rawPath = rawPath.replace(".testing/", ""); 
        isBranchOverride = true; 
    }
    else if (rawPath.startsWith(".raw/")) { 
        codeBranch = "raw"; 
        rawPath = rawPath.replace(".raw/", ""); 
        isBranchOverride = true; 
    }
    
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

try {
        let gitHubPath = "";
        let fileName = "";
        const pathParts = rawPath.split('/').filter(p => p);
        
        // Получаем версию для V3 (ss/sc/ff)
        const ssRes = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "functions/ver/ss.txt", ref: "main" 
        });
        const currentV = atob(ssRes.data.content).trim(); 

        // --- ЖЕЛЕЗНЫЙ РОУТИНГ ПО ВЕТКАМ ---
        
        if (isBranchOverride) {
            fileName = pathParts.pop()?.toLowerCase() || "index.html"; // добавь ?. и фолбек
            gitHubPath = pathParts.join('/') || ".";
        } else if (rawPath.startsWith(`${currentV}/ff/`)) {
            const cleanPath = rawPath.replace(`${currentV}/ff/`, "");
            const parts = cleanPath.split('/').filter(p => p);
            fileName = parts.pop().toLowerCase();
            gitHubPath = "functions" + (parts.length > 0 ? "/" + parts.join('/') : "");
            
        } else if (rawPath.startsWith(`${currentV}/ss/`)) {
            const cleanPath = rawPath.replace(`${currentV}/ss/`, "");
            const parts = cleanPath.split('/').filter(p => p);
            fileName = parts.pop().toLowerCase();
            gitHubPath = "site/html" + (parts.length > 0 ? "/" + parts.join('/') : "");
            
        } else if (rawPath.startsWith(`${currentV}/sc/`)) {
            const cleanPath = rawPath.replace(`${currentV}/sc/`, "");
            const parts = cleanPath.split('/').filter(p => p);
            fileName = parts.pop().toLowerCase();
            gitHubPath = "site/catalog" + (parts.length > 0 ? "/" + parts.join('/') : "");
            
} else {
    // Стандартные роуты для MAIN ветки
    const routes = {
        "bio/phxmale": "bio/main.html", "obfuscator": "obfuscator.html",
        "getkey": "getkey.html", "status": "status.html", "catalog": "catalog.html"
    };

    if (routes[rawPath]) {
        return serveFallback(octokit, OWNER, REPO, routes[rawPath], selectedLang);
    } else if (rawPath.startsWith("~/")) {
        codeBranch = "off";
        const cleanPath = rawPath.replace("~/", "");
        const parts = cleanPath.split('/').filter(p => p);
        fileName = parts.pop()?.toLowerCase() || "index.html";
        gitHubPath = parts.length > 0 ? parts.join("/") : ".";
    } else {
        codeBranch = "off";
        fileName = pathParts.pop()?.toLowerCase() || "index.html";
        gitHubPath = ".";
    }
}

        // Чистим путь и делаем запрос к нужной ветке (codeBranch)
        gitHubPath = gitHubPath.replace(/\/$/, "");
        
        const { data: items } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: gitHubPath, ref: codeBranch
        });

// 1. Ищем файл в списке, пробуя разные расширения
        const target = Array.isArray(items) && items.find(i => {
            const name = i.name.toLowerCase();
            const search = fileName.toLowerCase();
            
     return name === search || 
       name === `${search}.png`  ||
       name === `${search}.jpg`  ||
       name === `${search}.jpeg` ||
       name === `${search}.jpe`  ||
       name === `${search}.gif`  ||
       name === `${search}.bmp`  ||
       name === `${search}.webp` ||
       name === `${search}.avif` ||
       name === `${search}.apng` ||
       name === `${search}.svg`  ||
       name === `${search}.svgz` ||
       name === `${search}.ico`  ||
       name === `${search}.tif`  ||
       name === `${search}.tiff` ||
       name === `${search}.heic` ||
       name === `${search}.heif` ||
       name === `${search}.html` ||
       name === `${search}.htm`  ||
       name === `${search}.css`  ||
       name === `${search}.js`   ||
       name === `${search}.mjs`  ||
       name === `${search}.ts`   ||
       name === `${search}.txt`  ||
       name === `${search}.log`  ||
       name === `${search}.ini`  ||
       name === `${search}.cfg`  ||
       name === `${search}.md`   ||
       name === `${search}.csv`  ||
       name === `${search}.json` ||
       name === `${search}.xml`  ||
       name === `${search}.yaml` ||
       name === `${search}.yml`  ||
       name === `${search}.lua`  ||
       name === `${search}.luaz` ||
       name === `${search}.py`   ||
       name === `${search}.java` ||
       name === `${search}.c`    ||
       name === `${search}.cpp`  ||
       name === `${search}.cs`   ||
       name === `${search}.go`   ||
       name === `${search}.rs`   ||
       name === `${search}.php`  ||
       name === `${search}.rb`   ||
       name === `${search}.sh`   ||
       name === `${search}.bat`  ||
       name === `${search}.ps1`  ||
       name === `${search}.mp3`  ||
       name === `${search}.wav`  ||
       name === `${search}.ogg`  ||
       name === `${search}.aac`  ||
       name === `${search}.m4a`  ||
       name === `${search}.flac` ||
       name === `${search}.mp4`  ||
       name === `${search}.webm` ||
       name === `${search}.mov`  ||
       name === `${search}.avi`  ||
       name === `${search}.mkv`  ||
       name === `${search}.ttf`  ||
       name === `${search}.otf`  ||
       name === `${search}.woff` ||
       name === `${search}.woff2`||
       name === `${search}.zip`  ||
       name === `${search}.rar`  ||
       name === `${search}.7z`   ||
       name === `${search}.tar`  ||
       name === `${search}.gz`   ||
       name === `${search}.bz2`  ||
       name === `${search}.xz`   ||
       name === `${search}.iso`  ||
       name === `${search}.pdf`  ||
       name === `${search}.doc`  ||
       name === `${search}.docx` ||
       name === `${search}.xls`  ||
       name === `${search}.xlsx` ||
       name === `${search}.exe`  ||
       name === `${search}.msi`  ||
       name === `${search}.dll`  ||
       name === `${search}.bin`  ||
       name === `${search}.apk`  ||
       name === `${search}.wasm`;
     });

        
// 1. ЕСЛИ ФАЙЛА НЕТ -> Просто отдаем заглушку
        if (!target) return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang);

        // 2. ПРОВЕРКА ДОСТУПА
        if (!rawPath.startsWith("~/") && !isRoblox && ip !== MY_IP && request.headers.get('vellote-access') !== 'true') {
            // Логгер (без await)
            fetch("https://aqusu.pages.dev/v3/ff/logger", {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ ip, path: url.pathname, domain: host, userAgent })
            }).catch(() => {});

            return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang);
        }

        // 3. ОПРЕДЕЛЯЕМ MIME-ТИП (берём из target, который мы нашли выше)
        const realFileName = target.name.toLowerCase();
        const realExt = realFileName.split('.').pop();
        const mime = mimeTypes[realExt] || mimeTypes["default"];
        const isTextual = ["text/", "application/javascript", "application/json"].some(t => mime.startsWith(t));

        // 4. ЕДИНСТВЕННЫЙ ЗАПРОС КОДА (только если прошли проверку доступа)
        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        // ... дальше твой блок с let body и return Response

        let body;
        if (fileData.content) {
            const binaryString = atob(fileData.content);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) bytes[i] = binaryString.charCodeAt(i);
            
            if (isTextual) {
                body = new TextDecoder("utf-8").decode(bytes);
            } else {
                body = bytes;
            }
        } else {
            const res = await fetch(fileData.download_url);
            body = await res.arrayBuffer();
        }

        return new Response(body, {
            status: 200,
            headers: {
                "Content-Type": mime + (isTextual ? "; charset=UTF-8" : ""),
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "public, max-age=3600",
                "X-Content-Type-Options": "nosniff"
            }
        });

    } catch (e) {
        return new Response(`Vellote Error: ${e.message}`, { status: 500 });
    }
}

async function serveFallback(octokit, owner, repo, path, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/html/${path}`, ref: "main" });
        const html = new TextDecoder("utf-8").decode(Uint8Array.from(atob(fb.content), c => c.charCodeAt(0))).replace(/{{LANG}}/g, lang);
        return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=UTF-8" } });
    } catch {
        return new Response("Not Found", { status: 404 });
    }
}

async function serveDocsFallback(octokit, owner, repo, path, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/docs/${path}`, ref: "main" });
        const html = new TextDecoder("utf-8").decode(Uint8Array.from(atob(fb.content), c => c.charCodeAt(0))).replace(/{{LANG}}/g, lang);
        return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=UTF-8" } });
    } catch {
        return new Response("Docs Not Found", { status: 404 });
    }
}
