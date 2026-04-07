import { Octokit } from "@octokit/rest";
import loggerHandler from "./logger.js";

export async function onRequest(context) {
    const { request, env, waitUntil } = context;
    const url = new URL(request.url);
    const host = request.headers.get("host") || "";
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    
    let rawPath = url.pathname.replace(/^\/+/, "").replace(/\/+$/, "");
    const userAgent = request.headers.get("user-agent") || "";
    const ua = userAgent.toLowerCase();
    const ip = request.headers.get("cf-connecting-ip") || "0.0.0.0";
    const OWNER = "misterlerp";
    const REPO = "ML";
    const MY_IP = "77.52.212.190";
    const isOwner = ip === MY_IP;
    const isRoblox = ua.includes("roblox") || request.headers.get('vellote-access') === 'true';
    const isSpecialUA = ua.includes("ml/sa");
    if (!isOwner && !isRoblox && !isSpecialUA) {
    const logData = { body: { ip, path: url.pathname, domain: host, userAgent }, method: 'POST' };
    const mockRes = { status: () => ({ json: () => {}, end: () => {} }) }; waitUntil(loggerHandler(logData, mockRes).catch(() => {})); return new Response("Access Denied", { status: 403 }); }
    const paths = {
        "ui/editor":       "site/html/tools/guic/index.html",
        "ui/style":        "site/html/tools/guic/style.css",
        "ui/core":         "site/html/tools/guic/app.js",
        "ui/elements":     "site/html/tools/guic/ui_elements.js",
        "ui/props":        "site/html/tools/guic/properties.js",
        "ui/snapping":     "site/html/tools/guic/snapping.js",
        "ui/explorer":     "site/html/tools/guic/explorer.js",
        "ui/viewport":     "site/html/tools/guic/viewport.js",
        "ui/export":       "site/html/tools/guic/export_engine.js",
    };
    const directMappings = {
        "editor": "site/html/tools/guic/index.html",
        "gui-core": "site/html/tools/guic/app.js"
    };
    let gitHubPath = "";
    if (directMappings[rawPath]) { gitHubPath = directMappings[rawPath]; } 
    else if (paths[rawPath]) { gitHubPath = paths[rawPath]; }
    else if (rawPath.match(/^v\d+\/ss\//)) { gitHubPath = `site/html/${rawPath.replace(/^v\d+\/ss\//, "")}`; }
    else { gitHubPath = rawPath || "site/html/main.html"; }
    let codeBranch = "main";
    if (host.includes("cdn-misslua")) { codeBranch = "cdn"; }
    else if (host.includes("api-misslua")) { codeBranch = "api"; }
    else if (host.includes("raw.misslua")) { codeBranch = "raw"; }
    try {
        const { data: fileData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: gitHubPath, ref: codeBranch });
        const realExt = gitHubPath.split('.').pop().toLowerCase();
        const mimeTypes = { 'html': 'text/html', 'css':  'text/css', 'js':   'application/javascript', 'json': 'application/json', 'lua':  'text/plain', 'png':  'image/png' };
        const mime = mimeTypes[realExt] || "application/octet-stream";
        const isText = ["html", "css", "js", "json", "lua"].includes(realExt);
        const binaryString = atob(fileData.content);
        const bytes = new Uint8Array(binaryString.length); for (let i = 0; i < binaryString.length; i++) bytes[i] = binaryString.charCodeAt(i);
        const body = isText ? new TextDecoder("utf-8").decode(bytes) : bytes; return new Response(body, { status: 200, headers: { "Content-Type": mime + (isText ? "; charset=UTF-8" : ""), "Access-Control-Allow-Origin": "*", "X-Content-Type-Options": "nosniff" } }); } catch (e) { return new Response(`Not Found: ${gitHubPath}`, { status: 404 }); } }