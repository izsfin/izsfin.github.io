import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const url = new URL(req.url, `https://${host}`);
    
    // Очищаем путь от лишних слешей в начале
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";
    const userAgent = req.headers['user-agent'] || "Unknown";
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    // --- 1. ОПРЕДЕЛЕНИЕ ВЕТКИ ПО ДОМЕНУ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";

    if (host.includes("auth-winxs")) { codeBranch = "auth"; fallbackFile = "getkey.html"; }
    else if (host.includes("test-winxs")) { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("api-winxs")) { codeBranch = "api"; }
    else if (host.includes("raw-winxs")) { codeBranch = "raw"; }
    else if (host.includes("cdn-winxs")) { codeBranch = "cdn"; }
    else if (host.includes("offwinxs")) { codeBranch = "off"; }

    // --- 2. ПОЛУЧЕНИЕ СЕКРЕТКИ ИЗ GITHUB (BRANCH: MAIN) ---
    let secretWord = "night"; 
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        secretWord = secrets.secret_word.toLowerCase();
    } catch (e) { console.error("Error fetching secrets.json, using default 'night'"); }

    // --- 3. ПРОВЕРКА КЛЮЧА @SECRET ---
    let isSecretValid = false;
    if (rawPath.includes("@")) {
        const parts = rawPath.split("@");
        const providedSecret = parts.pop().toLowerCase().trim();
        rawPath = parts.join("@"); // Возвращаем путь без секрета
        if (providedSecret === secretWord) isSecretValid = true;
    }

    if (!rawPath || rawPath === "index") return serveFallback(res, fallbackFile, selectedLang);

    try {
        // --- 4. УМНЫЙ ПОИСК (РЕГИСТР И ПУТИ) ---
        // Если путь заканчивается на /, значит ищем "индексный" файл в этой папке
        const isFolderSearch = url.pathname.endsWith('/');
        
        const pathParts = rawPath.split('/').filter(p => p);
        const searchFileName = pathParts.pop().toLowerCase();
        const searchDir = pathParts.join('/');

        const { data: items } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch 
        });

        if (!Array.isArray(items)) throw new Error("Not a directory");

        const target = items.find(i => {
            const n = i.name.toLowerCase();
            const nNoExt = n.split('.')[0];
            return i.type === 'file' && (n === searchFileName || nNoExt === searchFileName);
        });

        // --- 5. ЛОГИКА ВЫДАЧИ ---
        if (target && !isSecretValid) {
            await sendToLogger(ip, rawPath, host, userAgent, "🛡️ Access Blocked (No Secret)");
            return serveFallback(res, fallbackFile, selectedLang);
        }

        if (!target) return serveFallback(res, fallbackFile, selectedLang);

        // Успех
        await sendToLogger(ip, target.name, host, userAgent, "✅ Script Loaded");

        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch 
        });
        
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();
        const mimes = { "lua": "text/plain", "js": "application/javascript", "png": "image/png", "jpg": "image/jpeg" };
        
        res.setHeader('Content-Type', mimes[ext] || "text/plain; charset=utf-8");
        res.setHeader('Access-Control-Allow-Origin', '*');
        return res.status(200).send(ext === 'png' || ext === 'jpg' ? content : content.toString('utf-8'));

    } catch (e) {
        return serveFallback(res, fallbackFile, selectedLang);
    }
}

async function serveFallback(res, file, lang) {
    try {
        const { data: fb } = await octokit.repos.getContent({ 
            owner: "nettoxi", repo: "winxs", path: `site/html/${file}`, ref: "main" 
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
