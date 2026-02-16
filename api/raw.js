import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";
const MY_IP = "77.52.212.190";

export default async function handler(req, res) {
    const host = req.headers.host;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const userAgent = req.headers['user-agent'] || "Unknown";
    const url = new URL(req.url, `http://${host}`);
    
    // Очищаем путь от лишних слешей
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    // --- 1. ОПРЕДЕЛЯЕМ ЛОГИКУ ДОМЕНОВ И ЗАГЛУШЕК ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    let isRootSearch = false; // Если true, ищем в корне репозитория, а не в site/html

    if (host.includes("test-winxs")) {
        codeBranch = "test";
        fallbackFile = "test.html";
    } else if (host.includes("status-winxs")) {
        fallbackFile = "status.html";
    } else if (host.includes("auth-winxs")) {
        // Логика для твоего домена авторизации
        codeBranch = "auth";
        fallbackFile = "getkey.html"; 
        isRootSearch = true; // В ветке auth файлы обычно в корне
    } else if (host.startsWith("auth-") || host.startsWith("authentication-")) {
        fallbackFile = "getkey.html"; 
    } else if (host.includes("cdn-winxs")) {
        codeBranch = "cdn";
        isRootSearch = true;
    }

    // Вспомогательная функция для логов
    const logAttempt = async (path, status) => {
        if (ip === MY_IP) return;
        try {
            await fetch(`https://${host}/api/logger`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    ip,
                    path: path || "root",
                    domain: host,
                    userAgent,
                    status
                })
            });
        } catch (e) { console.error("Logger error"); }
    };

    // --- 2. ЗАГРУЗКА СЕКРЕТОВ ---
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) { console.log("Secrets not found, using defaults"); }

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

    // Если зашли на корень
    if (rawPath === "" || rawPath === "/") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; 
    }

    try {
        // --- 4. ПОИСК ФАЙЛА В РЕПОЗИТОРИИ ---
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const subDir = parts.join('/');

        // Определяем папку поиска. Если не корень, то по дефолту site/html
        let searchDir = (isRootSearch) ? "" : "site/html";
        if (subDir) searchDir = searchDir ? `${searchDir}/${subDir}` : subDir;

        const { data: files } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch 
        });
        
        const target = files.find(f => f.name.split('.')[0].toLowerCase() === fileNameToSearch);

        // --- 5. ЛОГИКА ОГРАНИЧЕНИЯ ДОСТУПА ---
        if (!target || !isSecretValid) {
            if (target && !isSecretValid) await logAttempt(rawPath, "BLOCKED_NO_SECRET");

            const { data: fallbackData } = await octokit.repos.getContent({ 
                owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" 
            });
            let html = Buffer.from(fallbackData.content, 'base64').toString('utf-8');
            
            return res.status(200)
                .setHeader('Content-Type', 'text/html')
                .send(html.replace(/{{LANG}}/g, selectedLang));
        }

        // Успешный доступ
        await logAttempt(target.path, "SUCCESS_ACCESS");

        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch 
        });
        
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        const mimeTypes = {
            'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'svg': 'image/svg+xml', 'gif': 'image/gif', 'ico': 'image/x-icon',
            'html': 'text/html', 'css': 'text/css', 'js': 'application/javascript',
            'json': 'application/json', 'lua': 'text/plain', 'txt': 'text/plain'
        };

        const contentType = mimeTypes[ext] || 'application/octet-stream';
        res.setHeader('Content-Type', contentType);
        res.setHeader('Access-Control-Allow-Origin', '*'); 

        if (/image|font|video|audio/.test(contentType) || contentType === 'application/octet-stream') {
            return res.status(200).send(content);
        } else {
            let text = content.toString('utf-8');
            return res.status(200).send(text.replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        console.error(error);
        try {
            const { data: fallbackData } = await octokit.repos.getContent({ 
                owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" 
            });
            return res.status(200)
                .setHeader('Content-Type', 'text/html')
                .send(Buffer.from(fallbackData.content, 'base64').toString('utf-8'));
        } catch (e) {
            return res.status(404).end();
        }
    }
}
