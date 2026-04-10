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
   let codeBranch = "main";
   let internalPath = rawPath;    
   if (rawPath.startsWith("sa")) { codeBranch = "cdn"; internalPath = rawPath.replace(/^sa\/?/, ""); } 
   else if (rawPath.startsWith("get")) { codeBranch = "raw"; internalPath = rawPath.replace(/^get\/?/, ""); } 
   else if (rawPath.startsWith("srv")) { codeBranch = "api"; internalPath = rawPath.replace(/^srv\/?/, ""); } 
   else if (rawPath.startsWith("$")) { codeBranch = "off"; internalPath = rawPath.replace(/^\$\/?/, ""); }
   let isRootAccess = (internalPath === "");
   if (internalPath === "docs/universal") { const action = url.searchParams.get('action'); const headers = {  "Content-Type": "application/json; charset=UTF-8",  "Access-Control-Allow-Origin": "*",  "Cache-Control": "no-cache"  };
   try { if (action === 'posts') { const { data: indexData } = await octokit.repos.getContent({  owner: OWNER, repo: REPO, path: 'docs/index.json', ref: codeBranch  }); const content = atob(indexData.content); return new Response(content, { headers, status: 200 }); } return new Response(JSON.stringify({ error: "Invalid action" }), { headers, status: 400 }); } catch (apiErr) { return new Response(JSON.stringify({ error: apiErr.message }), { headers, status: 500 }); } }
   const paths = {
      "ui/creator/x/style":    "site/tools/guic/style.css",
      "ui/creator/x/core":     "site/tools/guic/app.js",
      "ui/creator/x/elements": "site/tools/guic/ui_elements.js",
      "ui/creator/x/props":    "site/tools/guic/properties.js",
      "ui/creator/x/snapping": "site/tools/guic/snapping.js",
      "ui/creator/x/explorer": "site/tools/guic/explorer.js",
      "ui/creator/x/viewport": "site/tools/guic/viewport.js",
      "ui/creator/x/export":   "site/tools/guic/export_engine.js",
   };
   const directMappings = {
    "editor": "site/tools/guic/index.html",
    "tools/ui/crator": "site/tools/guic/index.html",
    "catalog":  "site/catalog/html/catalog.html",
    "catalog/": "site/catalog/html/catalog-item.html",
   };
   let gitHubPath = "";  if (isRootAccess) { gitHubPath = "site/redict.html"; }  else if (directMappings[internalPath]) {  gitHubPath = directMappings[internalPath];  }  else if (paths[internalPath]) {  gitHubPath = paths[internalPath];  }  else {  gitHubPath = internalPath;  }
   const requestedExt = gitHubPath.split('.').pop().toLowerCase();
   const isSensitiveFile = requestedExt === 'lua' || requestedExt === 'luam';
   const isOwner = ip === MY_IP;
   const isRoblox = ua.includes("roblox") || request.headers.get('ml-access') === 'true';
   if (isSensitiveFile && !isOwner && !isRoblox ) { const logData = {  body: { ip, path: url.pathname, domain: host, userAgent, type: 'unauthorized_code_access' },  method: 'POST'  }; waitUntil(loggerHandler(logData, { status: () => ({ json: () => {}, end: () => {} }) }).catch(() => {})); return new Response("Access Denied: Code files are protected.", { status: 403 }); }
   try { const { data: fileData } = await octokit.repos.getContent({  owner: OWNER, repo: REPO, path: gitHubPath, ref: codeBranch  });
      const realExt = gitHubPath.split('.').pop().toLowerCase();
      const mimeTypes = { 
         'html': 'text/html', 'css': 'text/css', 'js': 'application/javascript', 
         'json': 'application/json', 'lua': 'text/plain', 'png': 'image/png', 
         'ico': 'image/x-icon',  
      }; 
      const mime = mimeTypes[realExt] || "application/octet-stream"; 
      const isText = ["html", "css", "js", "json", "lua"].includes(realExt);
      const binaryString = atob(fileData.content); const bytes = new Uint8Array(binaryString.length); for (let i = 0; i < binaryString.length; i++) bytes[i] = binaryString.charCodeAt(i); 
      const body = isText ? new TextDecoder("utf-8").decode(bytes) : bytes;
      return new Response(body, { status: 200, headers: { "Content-Type": mime + (isText ? "; charset=UTF-8" : ""), "Access-Control-Allow-Origin": "*", "X-Content-Type-Options": "nosniff", "Cache-Control": "no-cache" } }); } catch (e) { return new Response(`Not Found: ${gitHubPath} (Branch: ${codeBranch})`, { status: 404 }); } }