import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";
const MY_IP = "77.52.212.190";

export default async function handler(req, res) {
    const host = req.headers.host || "";
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const userAgent = req.headers['user-agent'] || "Unknown";
    const protocol = req.headers['x-forwarded-proto'] || 'https';
    
    const url = new URL(req.url, `${protocol}://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    // --- 1. ЛОГИКА ДОМЕНОВ ---
    let codeBranch = "main";
    let fallbackFile = "main.html";
    let isRootOnly = false; // Для этих доменов НЕ ищем в site/html

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
    } catch (e) { console.log("Secrets error"); }

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
    if (rawPath === "" || rawPath === "/" || rawPath.toLowerCase() === "index") {
        rawPath = fallbackFile.split('.')[0];
        isSecretValid = true; 
    }

    try {
        // --- 4. ПОИСК ФАЙЛА ---
        const parts = rawPath.split('/');
        const fileNameToSearch = parts.pop().toLowerCase();
        const subDirPath = parts.join('/');

        async function findFile(dir) {
            try {
                const { data: items } = await octokit.repos.getContent({ 
                    owner: OWNER, repo: REPO, path: dir, ref: codeBranch 
                });
                return items.find(i => i.name.split('.')[0].toLowerCase() === fileNameToSearch);
            } catch { return null; }
        }

        let target = null;
        if (isRootOnly) {
            // Для спец-доменов ищем только по указанному пути (от корня)
            target = await findFile(subDirPath);
        } else {
            // Для обычного домена: сначала site/html, потом корень
            target = await findFile(subDirPath ? `site/html/${subDirPath}` : "site/html");
            if (!target) target = await findFile(subDirPath);
        }

        // --- 5. ОТВЕТ ---
        if (!target || !isSecretValid) {
            const { data: fb } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: `site/html/${fallbackFile}`, ref: "main" });
            return res.status(200).setHeader('Content-Type', 'text/html').send(Buffer.from(fb.content, 'base64').toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

        const { data: fileData } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: target.path, ref: codeBranch });
        const content = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        // СУПЕР-ФИКС: MIME-типы, чтобы Lua НЕ СКАЧИВАЛСЯ
        const mimes = {
            "html": "text/html",
            "lua": "text/plain; charset=utf-8",
            "txt": "text/plain; charset=utf-8",
            "js": "application/javascript",
            "png": "image/png",
            "jpg": "image/jpeg"
        };

        const contentType = mimes[ext] || "text/plain"; // По дефолту текст, чтобы видеть код
        res.setHeader('Content-Type', contentType);
        res.setHeader('Access-Control-Allow-Origin', '*'); 

        // Логируем успех (без ожидания, чтобы не тормозить)
        fetch(`${protocol}://${host}/api/logger`, {
            method: 'POST',
            body: JSON.stringify({ ip, path: target.path, domain: host, status: "SUCCESS" })
        }).catch(() => {});

        if (/image|font|video/.test(contentType)) {
            return res.status(200).send(content);
        } else {
            return res.status(200).send(content.toString('utf-8').replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        return res.status(500).send("Critical error");
    }
}
