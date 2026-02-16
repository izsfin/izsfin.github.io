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

    // --- 1. ЛОГИКА ДОМЕНОВ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    let isRootOnly = false;

    if (host.includes("test-winxs")) {
        codeBranch = "test";
        fallbackFile = "test.html";
        isRootOnly = true;
    } else if (host.includes("auth-winxs")) {
        codeBranch = "auth";
        fallbackFile = "getkey.html"; 
        isRootOnly = true; 
    } else if (host.includes("cdn-winxs")) {
        codeBranch = "cdn";
        isRootOnly = true;
    }

    // --- 2. СЕКРЕТЫ ---
    let secrets = { secret_word: "night", symbols: ["@", "~"] };
    try {
        const { data: sData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) { console.error("!!! Secrets.json not found in main branch"); }

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

    // Корень домена
    if (rawPath === "" || rawPath === "/" || rawPath.toLowerCase() === "index") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; 
    }

    try {
        // --- 4. УЛУЧШЕННЫЙ ПОИСК ---
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const subDirPath = parts.join('/');

        async function findFile(dir) {
            try {
                // Если dir пустой, getContent берет корень репозитория
                const { data: items } = await octokit.repos.getContent({ 
                    owner: OWNER, repo: REPO, path: dir || "", ref: codeBranch 
                });
                
                if (!Array.isArray(items)) return null; // Если вернулся один файл, а не список

                return items.find(i => {
                    const nameParts = i.name.split('.');
                    const nameNoExt = (nameParts.length > 1 ? nameParts.slice(0, -1).join('.') : i.name).toLowerCase();
                    return nameNoExt === fileNameToSearch;
                });
            } catch (err) {
                console.log(`Searching in [${dir || "root"}] failed or empty.`);
                return null;
            }
        }

        let target = null;
        if (isRootOnly) {
            target = await findFile(subDirPath);
        } else {
            // Сначала site/html, потом корень
            target = await findFile(subDirPath ? `site/html/${subDirPath}` : "site/html");
            if (!target) {
                console.log(`File not found in site/html, trying root for path: ${subDirPath}`);
                target = await findFile(subDirPath);
            }
        }

        // --- 5. ОТВЕТ ---
        if (!target || !isSecretValid) {
            console.log(`Access Denied: target=${!!target}, secret=${isSecretValid}`);
            const { data: fb } = await octokit.repos.getContent({ 
                owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" 
            });
            return res.status(200)
                .setHeader('Content-Type', 'text/html')
                .send(Buffer.from(fb.content, 'base64').toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

        // Если нашли файл
        const { data: fileData } = await octokit.repos.getContent({ 
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch 
        });
        
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        const mimes = {
            "html": "text/html",
            "lua": "text/plain; charset=utf-8",
            "txt": "text/plain; charset=utf-8",
            "js": "application/javascript",
            "png": "image/png",
            "jpg": "image/jpeg"
        };

        res.setHeader('Content-Type', mimes[ext] || "text/plain; charset=utf-8");
        res.setHeader('Access-Control-Allow-Origin', '*'); 

        // Бинарники или текст
        if (/png|jpg|jpeg|gif|ico|pdf/.test(ext)) {
            return res.status(200).send(content);
        } else {
            return res.status(200).send(content.toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        console.error("CRITICAL ERROR:", error);
        return res.status(500).send("API Error");
    }
}
