import { Octokit } from "@octokit/rest";

export async function onRequest(context) { const { request, env } = context; const url = new URL(request.url); const host = request.headers.get("host") || ""; const octokit = new Octokit({ auth: env.GITHUB_TOKEN }); let rawPath = url.pathname.replace(/^\/+/, ""); const selectedLang = url.searchParams.get("lang") || "RU"; const userAgent = request.headers.get("user-agent") || ""; const ip = request.headers.get("cf-connecting-ip") || request.headers.get("x-forwarded-for") || "0.0.0.0";
    const OWNER = "misterlerp";
    const REPO = "ML";
    const MY_IP = "77.52.212.190";
    
    let fallbackFile = "main.html";  let codeBranch = "main"; let isBranchOverride = false;

    const ua = userAgent.toLowerCase();
    const isRoblox = ua.includes("roblox") || ua === "" || ua === "unknown" || request.headers.get('vellote-access') === 'true';
    const isOwner = ip === MY_IP;

    if (ua.includes("discordbot") || ua.includes("telegrambot") || ua.includes("twitterbot")) { return new Response("OK", { status: 200 }); }
    if (host.includes("cdn-misslua")) { codeBranch = "cdn"; isBranchOverride = true; } 
    else if (host.includes("api-misslua")) { codeBranch = "api"; isBranchOverride = true; } 
    else if (host.includes("raw-misslua")) { codeBranch = "raw"; isBranchOverride = true; }
    if (rawPath.startsWith(".cdn/")) {  codeBranch = "cdn";  rawPath = rawPath.replace(".cdn/", "");  isBranchOverride = true;  }
    else if (rawPath.startsWith(".api/")) {  codeBranch = "api";  rawPath = rawPath.replace(".api/", "");  isBranchOverride = true;  }
    else if (rawPath.startsWith(".testing/")) {  codeBranch = "test";  rawPath = rawPath.replace(".testing/", "");  isBranchOverride = true;  }
    else if (rawPath.startsWith(".raw/")) {  codeBranch = "raw";  rawPath = rawPath.replace(".raw/", "");  isBranchOverride = true;  }
    if (host.includes("vellote-docs") || rawPath.startsWith(".docs/")) { if (rawPath.startsWith(".docs/")) rawPath = rawPath.replace(".docs/", ""); const docFile = (!rawPath || rawPath === "index") ? "home.html" : (rawPath.endsWith(".html") ? rawPath : `${rawPath}.html`); return serveDocsFallback(octokit, OWNER, REPO, docFile, selectedLang); }
    if (rawPath.startsWith("v3/ss/tools/guic/")) {
    let filePath = rawPath.replace("v3/ss/tools/guic/", ""); if (!filePath || filePath === "" || filePath.endsWith("/")) { filePath = "index.html"; }
    const ext = filePath.split('.').pop();
    const mimeTypes = {
        'css': 'text/css',
        'js': 'application/javascript',
        'html': 'text/html',
        'json': 'application/json',
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'svg': 'image/svg+xml',
        'ico': 'image/x-icon'
    };
    const mime = mimeTypes[ext] || 'text/plain';
    
    try {
        const { data: file } = await octokit.repos.getContent({ owner: OWNER,  repo: REPO,  path: `site/guic/${filePath}`,  ref: "main" });
        const content = atob(file.content); return new Response(content, { status: 200, headers: { "Content-Type": mime + (ext === 'js' || ext === 'css' ? "; charset=UTF-8" : ""), "Access-Control-Allow-Origin": "*", "Cache-Control": "public, max-age=3600" } }); } catch (e) { console.log(`GUIC file not found: site/guic/${filePath}`); return new Response(`File not found: ${filePath}`, { status: 404 }); } }

if (rawPath.startsWith("functions/")) {
 const isSpecialUA = ua.includes("ML/sa") || isRoblox;  if (!isSpecialUA && !isOwner) { return new Response("Access Denied", { status: 403 }); }
 let targetPath = rawPath; if (!targetPath.toLowerCase().endsWith(".js")) { targetPath += ".js"; } 
 try {
  const { data: file } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: targetPath, ref: "main" });
  const content = atob(file.content); return new Response(content, {  status: 200,  headers: { "Content-Type": "application/javascript; charset=UTF-8", "Access-Control-Allow-Origin": "*", "X-Content-Type-Options": "nosniff" } }); } catch (e) {
 try {
    const { data: fileRaw } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: rawPath, ref: "main" });
    const contentRaw = atob(fileRaw.content); return new Response(contentRaw, { status: 200, headers: { "Content-Type": "application/javascript; charset=UTF-8" } }); } catch (e2) { return new Response("Function Not Found", { status: 404 }); } }
}

try { let gitHubPath = ""; let fileName = ""; const pathParts = rawPath.split('/').filter(p => p);
 const ssRes = await octokit.repos.getContent({  owner: OWNER, repo: REPO, path: "functions/ver/ss.txt", ref: "main"   });  const currentV = atob(ssRes.data.content).trim();  if (isBranchOverride) {  if (pathParts.length === 0) { return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang); }  fileName = pathParts.pop()?.toLowerCase() || "index.html";  gitHubPath = pathParts.join('/') || ""; }else if (rawPath.startsWith(`${currentV}/ff/`)) { const cleanPath = rawPath.replace(`${currentV}/ff/`, ""); const parts = cleanPath.split('/').filter(p => p); fileName = parts.pop().toLowerCase(); gitHubPath = "functions" + (parts.length > 0 ? "/" + parts.join('/') : ""); } else if (rawPath.startsWith(`${currentV}/ss/`)) { const cleanPath = rawPath.replace(`${currentV}/ss/`, ""); const parts = cleanPath.split('/').filter(p => p); fileName = parts.pop().toLowerCase(); gitHubPath = "site/html" + (parts.length > 0 ? "/" + parts.join('/') : "");     } else if (rawPath.startsWith(`${currentV}/sc/`)) { const cleanPath = rawPath.replace(`${currentV}/sc/`, ""); const parts = cleanPath.split('/').filter(p => p); fileName = parts.pop().toLowerCase(); gitHubPath = "site/catalog" + (parts.length > 0 ? "/" + parts.join('/') : "");
            
} else {
    const rawRoutes = {
       "tools/guic":                     "tools/guic/index.html",
        "forum":                          "forum/home.html",
        "forum/auth":                     "forum/auth.html",
        "forum/create":                   "forum/create.html",
        "catalog":                        "catalog.html",
        "tools":                          "tools/home.html",
        "tools/ui/creator":               "tools/guic/index.html",
        "tools/luau/obfuscator":          "tools/luau/obfuscator.html",
        "tools/luau/minifycator":         "tools/luau/minifycator.html",
        "tools/custom.syntax/luaz":       "tools/cs/LuaZ_obfuscator.html",
        "tools/custom.syntax/luam":       "tools/cs/LuaM_obfuscator.html",
        "tools/custom.syntax/nuqau":      "tools/cs/Nuqau_obfuscator.html",
        "bio/phxmale": "bio/main.html",
        "obfuscator":  "obfuscator.html",
        "getkey":      "getkey.html",
        "status":      "status.html",
    }; 

    const normalizedPath = rawPath.toLowerCase(); if (rawRoutes[normalizedPath]) { return serveFallback(octokit, OWNER, REPO, rawRoutes[normalizedPath], selectedLang); } else if (normalizedPath.startsWith("forum/")) { return serveFallback(octokit, OWNER, REPO, "forum/post.html", selectedLang); } else if (normalizedPath.startsWith("catalog/")) { return serveFallback(octokit, OWNER, REPO, "catalog-item.html", selectedLang); } else if (rawPath.startsWith("~/")) {  codeBranch = "off";  const cleanPath = rawPath.replace("~/", "");  const parts = cleanPath.split('/').filter(p => p);  fileName = parts.pop()?.toLowerCase() || "index.html";  gitHubPath = parts.length > 0 ? parts.join("/") : "."; } else { codeBranch = "off";  fileName = pathParts.pop()?.toLowerCase() || "index.html"; gitHubPath = "."; } } gitHubPath = gitHubPath.replace(/\/$/, ""); const { data: items } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: gitHubPath, ref: codeBranch  }); 
    const target = Array.isArray(items) && items.find(i => { const name = i.name.toLowerCase(); const search = fileName.toLowerCase();
            
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

        
   if (!target) return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang); if (!rawPath.startsWith("~/") && !isRoblox && ip !== MY_IP && request.headers.get('vellote-access') !== 'true') { fetch("https://misslua.pages.dev/functions/logger.js", { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ip, path: url.pathname, domain: host, userAgent }) }).catch(() => {}); return serveFallback(octokit, OWNER, REPO, fallbackFile, selectedLang); }

        const realFileName = target.name.toLowerCase();
        const realExt = realFileName.split('.').pop();
        const mime = mimeTypes[realExt] || mimeTypes["default"];
        const isTextual = ["text/", "application/javascript", "application/json"].some(t => mime.startsWith(t));
        const { data: fileData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: target.path, ref: codeBranch });
        let body; if (fileData.content) { const binaryString = atob(fileData.content); const bytes = new Uint8Array(binaryString.length); for (let i = 0; i < binaryString.length; i++) bytes[i] = binaryString.charCodeAt(i); if (isTextual) { body = new TextDecoder("utf-8").decode(bytes); } else { body = bytes; } } else { const res = await fetch(fileData.download_url); body = await res.arrayBuffer(); } return new Response(body, { status: 200, headers: { "Content-Type": mime + (isTextual ? "; charset=UTF-8" : ""), "Access-Control-Allow-Origin": "*", "Cache-Control": "public, max-age=3600", "X-Content-Type-Options": "nosniff" } }); } catch (e) { return new Response(`Vellote Error: ${e.message}`, { status: 500 }); } }

async function serveFallback(octokit, owner, repo, path, lang) { try { const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/html/${path}`, ref: "main" }); const html = new TextDecoder("utf-8").decode(Uint8Array.from(atob(fb.content), c => c.charCodeAt(0))).replace(/{{LANG}}/g, lang); return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=UTF-8" } }); } catch { return new Response("Not Found", { status: 404 }); } }

async function serveDocsFallback(octokit, owner, repo, path, lang) { try { const { data: fb } = await octokit.repos.getContent({ owner, repo, path: `site/docs/${path}`, ref: "main" }); const html = new TextDecoder("utf-8").decode(Uint8Array.from(atob(fb.content), c => c.charCodeAt(0))).replace(/{{LANG}}/g, lang); return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=UTF-8" } }); } catch { return new Response("Docs Not Found", { status: 404 }); } }