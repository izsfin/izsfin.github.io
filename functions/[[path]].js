import { Octokit } from "@octokit/rest";

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });

    // --- НАСТРОЙКА КОНКРЕТНОЙ ВЕТКИ ---
    // В каждой ветке (main, off, cdn) просто меняй это значение:
    const BRANCH = "testing"; 
    
    const OWNER = "misterlerp";
    const REPO = "ML";
    const MY_IP = "77.52.212.190";

    // Определение пути
    let rawPath = url.pathname.replace(/^\/+/, "").replace(/\/+$/, "");
    
    const mappings = {
        "editor": "site/html/tools/guic/index.html",
        "catalog": "site/html/catalog.html",
        "": "site/html/main.html"
    };

    const gitHubPath = mappings[rawPath] || rawPath || "site/html/main.html";

    // --- БЛОК ЗАЩИТЫ ---
    const ip = request.headers.get("cf-connecting-ip") || "0.0.0.0";
    const ua = (request.headers.get("user-agent") || "").toLowerCase();
    const isSensitive = gitHubPath.endsWith('.lua') || gitHubPath.endsWith('.luac');
    
    const isOwner = ip === MY_IP;
    const isTrusted = ua.includes("roblox") || ua.includes("ml/sa") || request.headers.get('ml-access') === 'true';

    if (isSensitive && !isOwner && !isTrusted) {
        return new Response("Access Denied", { status: 403 });
    }
    try {
        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, 
            repo: REPO, 
            path: gitHubPath, 
            ref: BRANCH 
        });

        const ext = gitHubPath.split('.').pop().toLowerCase();
        const mimeTypes = { 
            'html': 'text/html', 
            'css': 'text/css', 
            'js': 'application/javascript', 
            'json': 'application/json', 
            'lua': 'text/plain', 
            'png': 'image/png' 
        };

        const contentType = mimeTypes[ext] || "application/octet-stream";
        const isText = ["html", "css", "js", "json", "lua"].includes(ext);

        const binaryString = atob(fileData.content);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) bytes[i] = binaryString.charCodeAt(i);

        return new Response(isText ? new TextDecoder().decode(bytes) : bytes, {
            status: 200,
            headers: {
                "Content-Type": contentType + (isText ? "; charset=UTF-8" : ""),
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "no-cache"
            }
        });
    } catch (e) {
        return new Response(`404: File not found in branch [${BRANCH}]`, { status: 404 });
    }
}