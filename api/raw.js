import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const protocol = req.headers['x-forwarded-proto'] || 'https';
    const url = new URL(req.url, `${protocol}://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    // --- 1. КАРТА: ДОМЕН -> ВЕТКА ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    let searchDir = ""; // По умолчанию ищем в корне ветки

    if (host.includes("auth-winxs")) {
        codeBranch = "auth";
        fallbackFile = "getkey.html";
    } else if (host.includes("test-winxs")) {
        codeBranch = "test";
        fallbackFile = "test.html";
    } else if (host.includes("cdn-winxs")) {
        codeBranch = "cdn";
    } else if (host.includes("off-winxs")) {
        codeBranch = "off"; // Если есть ветка off, иначе ставь main
        fallbackFile = "main.html";
        searchDir = "site/html"; // Для off-домена приоритет папке сайта
    } else if (host.includes("api-winxs")) {
        codeBranch = "api";
    } else if (host.includes("raw-winxs")) {
        codeBranch = "raw";
    } else {
        // Дефолт для основного домена или если зашли по прямой ссылке верселя
        codeBranch = "main";
        searchDir = "site/html";
    }

    // --- 2. СЕКРЕТЫ (Всегда берем из main для синхронизации) ---
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) { console.error("Secrets.json missing"); }

    // --- 3. ПРОВЕРКА СЕКРЕТА ---
    let isSecretValid = false;
    const symbol = secrets.symbols.find(s => rawPath.includes(s));
    if (symbol) {
        const [name, secret] = rawPath.split(symbol);
        if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
            rawPath = name; 
            isSecretValid = true;
        }
    }

    // Корень (заглушка)
    if (rawPath === "" || rawPath === "/" || rawPath.toLowerCase() === "index") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; 
    }

    try {
        // --- 4. ПОИСК ФАЙЛА (РЕГИСТРОНЕЗАВИСИМЫЙ) ---
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const currentSubDir = parts.join('/');

        async function findInGitHub(targetDir) {
            try {
                const { data: items } = await octokit.repos.getContent({ 
                    owner: OWNER, repo: REPO, path: targetDir || "", ref: codeBranch 
                });
                if (!Array.isArray(items)) return null;
                return items.find(i => {
                    const nameNoExt = i.name.split('.').slice(0, -1).join('.') || i.name;
                    return nameNoExt.toLowerCase() === fileNameToSearch;
                });
            } catch { return null; }
        }

        let target = null;
        
        // Сначала ищем по стратегии домена
        if (searchDir) {
            const pathWithSearchDir = currentSubDir ? `${searchDir}/${currentSubDir}` : searchDir;
            target = await findInGitHub(pathWithSearchDir);
        }

        // Если не нашли в спец. папке или домен "складской" — ищем в корне ветки
        if (!target) {
            target = await findInGitHub(currentSubDir);
        }

        // --- 5. ВЫДАЧА ---
        if (!target || !isSecretValid) {
            const { data: fb } = await octokit.repos.getContent({ 
                owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" 
            });
            return res.status(200).setHeader('Content-Type', 'text/html').send(Buffer.from(fb.content, 'base64').toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

        const { data: fileData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: target.path, ref: codeBranch });
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        const mimes = {
            "html": "text/html",
            "lua": "text/plain; charset=utf-8",
            "js": "application/javascript",
            "png": "image/png",
            "jpg": "image/jpeg",
            "txt": "text/plain; charset=utf-8"
        };

        res.setHeader('Content-Type', mimes[ext] || "text/plain; charset=utf-8");
        res.setHeader('Access-Control-Allow-Origin', '*');

        if (/png|jpg|jpeg|gif|ico/.test(ext)) {
            return res.status(200).send(content);
        } else {
            return res.status(200).send(content.toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        return res.status(500).send("API Error");
    }
}
