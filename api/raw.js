import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const url = new URL(req.url, `https://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    // --- 1. ПРИВЯЗКА ДОМЕН -> ВЕТКА ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    let isSiteMode = false;

    if (host.includes("auth-winxs")) { codeBranch = "auth"; fallbackFile = "getkey.html"; }
    else if (host.includes("test-winxs")) { codeBranch = "test"; fallbackFile = "test.html"; }
    else if (host.includes("cdn-winxs")) { codeBranch = "cdn"; }
    else if (host.includes("api-winxs")) { codeBranch = "api"; }
    else if (host.includes("raw-winxs")) { codeBranch = "raw"; }
    else if (host.includes("off-winxs")) { codeBranch = "off"; isSiteMode = true; }
    else { isSiteMode = true; }

    // --- 2. СЕКРЕТЫ (Всегда из main) ---
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) { console.error("Secrets.json missing in main branch"); }

    // --- 3. ПРОВЕРКА ДОСТУПА ---
    let isSecretValid = false;
    
    // Складским доменам секрет не нужен
    if (host.includes("api-winxs") || host.includes("raw-winxs") || host.includes("cdn-winxs")) {
        isSecretValid = true;
    }

    const symbol = secrets.symbols.find(s => rawPath.includes(s));
    if (symbol) {
        const [name, secret] = rawPath.split(symbol);
        if (secret && secret.toLowerCase().trim() === secrets.secret_word.toLowerCase().trim()) {
            rawPath = name; 
            isSecretValid = true;
        }
    }

    // Обработка главной страницы
    if (!rawPath || rawPath === "/" || rawPath.toLowerCase() === "index") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; 
    }

    try {
        const parts = rawPath.split('/').filter(p => p !== "");
        const fileNameToSearch = parts.pop().toLowerCase().trim();
        const dirPath = parts.join('/');

        async function findFileInGH(targetDir) {
            try {
                const { data: items } = await octokit.repos.getContent({ 
                    owner: OWNER, repo: REPO, path: targetDir || "", ref: codeBranch 
                });
                if (!Array.isArray(items)) return null;
                return items.find(i => {
                    const n = i.name.toLowerCase();
                    return n === fileNameToSearch || n.split('.')[0] === fileNameToSearch;
                });
            } catch { return null; }
        }

        let target = null;
        if (isSiteMode) {
            target = await findFileInGH(dirPath ? `site/html/${dirPath}` : "site/html");
        }
        
        if (!target) target = await findFileInGH(dirPath);

        // --- 4. ВЫДАЧА ---
        if (!target || !isSecretValid) {
            const { data: fb } = await octokit.repos.getContent({ 
                owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" 
            });
            return res.status(200).setHeader('Content-Type', 'text/html')
                .send(Buffer.from(fb.content, 'base64').toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch 
        });
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        const mimes = { 
            "lua": "text/plain; charset=utf-8", 
            "html": "text/html", "js": "application/javascript",
            "png": "image/png", "jpg": "image/jpeg", "txt": "text/plain; charset=utf-8"
        };
        
        res.setHeader('Content-Type', mimes[ext] || "text/plain; charset=utf-8");
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');

        if (/png|jpg|jpeg|gif|ico/.test(ext)) {
            return res.status(200).send(content);
        } else {
            return res.status(200).send(content.toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }
    } catch (e) { return res.status(500).send("Critical API Error"); }
}
