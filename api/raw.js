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
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    // 1. ОПРЕДЕЛЯЕМ ВЕТКУ И ФАЙЛ-ЗАГЛУШКУ
    let codeBranch = "main";
    let fallbackFile = "main.html";

    if (host.includes("test-winxs")) {
        codeBranch = "test";
        fallbackFile = "test.html";
    } else if (host.includes("status-winxs")) {
        fallbackFile = "status.html";
    } else if (host.startsWith("auth-") || host.startsWith("authentication-")) {
        fallbackFile = "auth.html";
    } else if (host.includes("cdn-winxs")) {
        codeBranch = "cdn";
    }

    // Вспомогательная функция для логирования
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
                    status // Доп. инфо: зашел с секретом или без
                })
            });
        } catch (e) { console.error("Logger error"); }
    };

    // 2. ЗАГРУЗКА СЕКРЕТОВ
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) {}

    // 3. ПРОВЕРКА СЕКРЕТА
    let isSecretValid = false;
    const symbol = secrets.symbols.find(s => rawPath.includes(s));
    if (symbol) {
        const [name, secret] = rawPath.split(symbol);
        if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
            rawPath = name; 
            isSecretValid = true;
        }
    }

    // Если это корень сайта
    if (rawPath === "" || rawPath === "/") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; // Корень всегда доступен
    }

    try {
        // 4. ПОИСК ФАЙЛА
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const subDir = parts.join('/');

        let searchDir = codeBranch === "main" ? "site/html" : "";
        if (subDir) searchDir = searchDir ? `${searchDir}/${subDir}` : subDir;

        const { data: files } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch });
        const target = files.find(f => f.name.split('.')[0].toLowerCase() === fileNameToSearch);

        // --- ЛОГИКА ЗАЩИТЫ И ОТДАЧИ ---
        
        // Если файла нет ИЛИ секрет неверный — отдаем заглушку
        if (!target || !isSecretValid) {
            if (target && !isSecretValid) await logAttempt(rawPath, "BLOCKED_NO_SECRET");

            const { data: fallbackData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" });
            let html = Buffer.from(fallbackData.content, 'base64').toString('utf-8');
            return res.status(200).setHeader('Content-Type', 'text/html').send(html.replace(/{{LANG}}/g, selectedLang));
        }

        // Если все ок — логируем успех и отдаем реальный файл
        await logAttempt(target.path, "SUCCESS_ACCESS");

        const { data: fileData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: target.path, ref: codeBranch });
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        // --- ТВОИ MIMES ---
        const mimeTypes = {
            'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'svg': 'image/svg+xml', 'gif': 'image/gif', 'ico': 'image/x-icon',
            'html': 'text/html', 'css': 'text/css', 'js': 'application/javascript',
            'json': 'application/json', 'lua': 'text/plain', 'txt': 'text/plain'
        };

        const contentType = mimeTypes[ext] || 'application/octet-stream';
        res.setHeader('Content-Type', contentType);

        if (/image|font|video|audio/.test(contentType) || contentType === 'application/octet-stream') {
            return res.status(200).send(content);
        } else {
            let text = content.toString('utf-8');
            return res.status(200).send(text.replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        // В случае любой ошибки — просто отдаем заглушку, чтобы не палиться
        const { data: fallbackData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" });
        return res.status(200).send(Buffer.from(fallbackData.content, 'base64').toString('utf-8'));
    }
}
