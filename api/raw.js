import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host;
    const url = new URL(req.url, `http://${host}`);
    let fullPath = url.pathname.replace(/^\/+/, ""); // Убираем слэш в начале
    const selectedLang = req.query.lang || "RU";
    const isDev = req.query.dev === "true";

    // 1. ОПРЕДЕЛЯЕМ ВЕТКУ (Branch)
    let codeBranch = "main";
    if (host === "cdn-winxs.vercel.app") codeBranch = "cdn";
    if (host === "test-winxs.vercel.app") codeBranch = "test";

    // --- ЛОГИКА СЕКРЕТНЫХ ПУТЕЙ (СУФФИКСОВ) ---
    // Если путь пустой (главная), ставим main.html по умолчанию
    if (fullPath === "" || fullPath === "/") {
        fullPath = "site/html/main.html";
    }

    try {
        const { data: secretData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        const secrets = JSON.parse(Buffer.from(secretData.content, 'base64').toString('utf-8'));
        
        // Ищем символ (~ или @) в пути
        const usedSymbol = secrets.symbols.find(s => fullPath.includes(s));
        
        if (usedSymbol) {
            const parts = fullPath.split(usedSymbol);
            const fileName = parts[0]; 
            const secretPart = parts[1];

            if (secretPart === secrets.secret_word) {
                // Если секрет совпал, перенаправляем на файл в папке html
                fullPath = `site/html/${fileName}.html`;
            }
        }
    } catch (e) {
        // Если конфиг секретов не найден, идем дальше по обычному пути
    }

    try {
        // 2. СТАТИКА (Картинки, CSS и т.д.)
        const isStatic = /\.(svg|png|jpg|jpeg|css|ico|gif)$/i.test(fullPath);
        
        if (isStatic) {
            const { data: fileData } = await octokit.repos.getContent({
                owner: OWNER,
                repo: REPO,
                path: fullPath,
                ref: codeBranch
            });

            const content = Buffer.from(fileData.content, 'base64');
            const ext = fullPath.split('.').pop().toLowerCase();
            const mimeTypes = {
                'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
                'svg': 'image/svg+xml', 'css': 'text/css', 'ico': 'image/x-icon', 'gif': 'image/gif'
            };

            return res.status(200)
                .setHeader('Content-Type', mimeTypes[ext] || 'application/octet-stream')
                .setHeader('Cache-Control', 'public, max-age=3600')
                .send(content);
        }

        // 3. ОБРАБОТКА HTML (с подстановкой языка)
        // Если путь не содержит .html и это не статика, пробуем добавить .html
        let githubPath = fullPath;
        if (!githubPath.includes('.') && !githubPath.startsWith('site/html/')) {
            githubPath = `site/html/${fullPath}.html`;
        }

        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER,
            repo: REPO,
            path: githubPath,
            ref: codeBranch
        });

        let html = Buffer.from(fileData.content, 'base64').toString('utf-8');
        
        // Магия замены переменной языка
        html = html.replace(/{{LANG}}/g, selectedLang);

        return res.status(200)
            .setHeader('Content-Type', 'text/html')
            .send(html);

    } catch (error) {
        console.error("Error fetching file:", error.message);
        return res.status(404).send(`File not found: ${fullPath} (Branch: ${codeBranch})`);
    }
}
