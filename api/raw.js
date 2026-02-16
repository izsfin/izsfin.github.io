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

    // 1. ОПРЕДЕЛЯЕМ ЛОГИКУ ДОМЕНОВ И ЗАГЛУШЕК
    let codeBranch = "main";
    let fallbackFile = "main.html";

    if (host.includes("test-winxs")) {
        codeBranch = "test";
        fallbackFile = "test.html";
    } else if (host.includes("status-winxs")) {
        fallbackFile = "status.html";
    } else if (host.startsWith("auth-") || host.startsWith("authentication-")) {
        // Твой новый домен для ключ-системы
        fallbackFile = "getkey.html"; 
    } else if (host.includes("cdn-winxs")) {
        codeBranch = "cdn";
    }

    // Вспомогательная функция для отправки отчетов в Дискорд через твой logger.js
    const logAttempt = async (path, status) => {
        if (ip === MY_IP) return; // Твой IP не логируем
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

    // 2. ЗАГРУЗКА СЕКРЕТОВ ИЗ GITHUB
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) { console.log("Secrets not found, using defaults"); }

    // 3. ПРОВЕРКА СЕКРЕТНОГО СЛОВА В ПУТИ (например: file@night)
    let isSecretValid = false;
    const symbol = secrets.symbols.find(s => rawPath.includes(s));
    
    if (symbol) {
        const [name, secret] = rawPath.split(symbol);
        if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
            rawPath = name; 
            isSecretValid = true;
        }
    }

    // Если зашли просто на корень домена (например auth-winxs.vercel.app/)
    if (rawPath === "" || rawPath === "/") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; // Корень всегда разрешен (покажет заглушку)
    }

    try {
        // 4. ПОИСК ФАЙЛА В РЕПОЗИТОРИИ
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const subDir = parts.join('/');

        // Определяем папку поиска (для main ветки это site/html)
        let searchDir = codeBranch === "main" ? "site/html" : "";
        if (subDir) searchDir = searchDir ? `${searchDir}/${subDir}` : subDir;

        const { data: files } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch 
        });
        
        // Ищем файл игнорируя расширение
        const target = files.find(f => f.name.split('.')[0].toLowerCase() === fileNameToSearch);

        // 5. ЛОГИКА ОГРАНИЧЕНИЯ ДОСТУПА
        // Если файла нет ИЛИ файл есть, но секрет не введен — отдаем заглушку домена
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

        // Если секрет верный и файл найден — логируем успех и отдаем контент
        await logAttempt(target.path, "SUCCESS_ACCESS");

        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch 
        });
        
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        // Настройка MIME-типов
        const mimeTypes = {
            'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'svg': 'image/svg+xml', 'gif': 'image/gif', 'ico': 'image/x-icon',
            'html': 'text/html', 'css': 'text/css', 'js': 'application/javascript',
            'json': 'application/json', 'lua': 'text/plain', 'txt': 'text/plain'
        };

        const contentType = mimeTypes[ext] || 'application/octet-stream';
        res.setHeader('Content-Type', contentType);
        res.setHeader('Access-Control-Allow-Origin', '*'); // Разрешаем доступ отовсюду

        // Если это бинарный файл (картинка), отправляем буфер, если текст — заменяем LANG
        if (/image|font|video|audio/.test(contentType) || contentType === 'application/octet-stream') {
            return res.status(200).send(content);
        } else {
            let text = content.toString('utf-8');
            return res.status(200).send(text.replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        // При любой ошибке тихо отдаем заглушку, чтобы не палить структуру папок
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
