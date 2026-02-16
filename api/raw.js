import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";
const MY_IP = "77.52.212.190";

export default async function handler(req, res) {
    // Проверка токена сразу
    if (!process.env.GITHUB_TOKEN) {
        return res.status(500).json({ error: "GITHUB_TOKEN is not configured in Vercel env" });
    }

    const host = req.headers.host;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const userAgent = req.headers['user-agent'] || "Unknown";
    
    // Используем современный URL API
    const protocol = req.headers['x-forwarded-proto'] || 'http';
    const url = new URL(req.url, `${protocol}://${host}`);
    
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    // --- 1. ЛОГИКА ДОМЕНОВ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    let isRootSearch = false;

    if (host.includes("test-winxs")) {
        codeBranch = "test";
        fallbackFile = "test.html";
    } else if (host.includes("auth-winxs")) {
        codeBranch = "auth";
        fallbackFile = "getkey.html"; 
        isRootSearch = true; 
    } else if (host.includes("cdn-winxs")) {
        codeBranch = "cdn";
        isRootSearch = true;
    }

    // Исправленный логгер (не падает при ошибке 401)
    const logAttempt = async (path, status) => {
        if (ip === MY_IP) return;
        try {
            await fetch(`${protocol}://${host}/api/logger`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ ip, path: path || "root", domain: host, userAgent, status })
            }).catch(() => {}); // Игнорим ошибки логгера, чтобы не вешать скрипт
        } catch (e) {}
    };

    // --- 2. ЗАГРУЗКА СЕКРЕТОВ ---
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) { console.log("Secrets.json not found in GitHub"); }

    // --- 3. ПРОВЕРКА СЕКРЕТНОГО СЛОВА ---
    let isSecretValid = false;
    const symbol = secrets.symbols.find(s => rawPath.includes(s));
    
    if (symbol) {
        const [name, secret] = rawPath.split(symbol);
        if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
            rawPath = name; 
            isSecretValid = true;
        }
    }

    if (rawPath === "" || rawPath === "/" || rawPath.toLowerCase() === "index") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; 
    }

    try {
        // --- 4. ПОИСК ФАЙЛА (РЕГИСТРОНЕЗАВИСИМЫЙ) ---
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const subDirPath = parts.join('/');

        async function findFileInDir(dirPath) {
            try {
                const { data: items } = await octokit.repos.getContent({ 
                    owner: OWNER, repo: REPO, path: dirPath, ref: codeBranch 
                });
                return items.find(item => {
                    const nameWithoutExt = item.name.split('.')[0].toLowerCase();
                    return nameWithoutExt === fileNameToSearch;
                });
            } catch (e) { return null; }
        }

        let target = null;
        // 1. Пробуем в site/html (если не форсим корень)
        if (!isRootSearch) {
            target = await findFileInDir(subDirPath ? `site/html/${subDirPath}` : "site/html");
        }
        // 2. Если не нашли, ищем в корне или подпапках корня
        if (!target) {
            target = await findFileInDir(subDirPath);
        }

        // --- 5. ОТДАЧА КОНТЕНТА ---
        if (!target || !isSecretValid) {
            if (target && !isSecretValid) await logAttempt(rawPath, "BLOCKED_NO_SECRET");
            
            const { data: fb } = await octokit.repos.getContent({ 
                owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" 
            });
            let html = Buffer.from(fb.content, 'base64').toString('utf-8');
            return res.status(200).setHeader('Content-Type', 'text/html').send(html.replace(/{{LANG}}/g, selectedLang));
        }

        await logAttempt(target.path, "SUCCESS_ACCESS");
        
        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch 
        });
        
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        // Мим-типы (добавь свои сюда)
        const mimeTypes = {
            "html": "text/html",
            "lua": "text/plain",
            "png": "image/png",
            "jpg": "image/jpeg",
            "js": "application/javascript"
        };

        const contentType = mimeTypes[ext] || "application/octet-stream";
        res.setHeader('Content-Type', contentType);
        res.setHeader('Access-Control-Allow-Origin', '*'); 

        if (/image|font|video|audio/.test(contentType) || contentType === 'application/octet-stream') {
            return res.status(200).send(content);
        } else {
            return res.status(200).send(content.toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        console.error("Critical Error:", error);
        return res.status(500).send("Internal Server Error");
    }
}
