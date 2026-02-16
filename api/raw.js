import { Octokit } from "@octokit/rest";

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const OWNER = "nettoxi";
const REPO = "winxs";

export default async function handler(req, res) {
    const host = req.headers.host;
    const url = new URL(req.url, `http://${host}`);
    let rawPath = url.pathname.replace(/^\/+/, ""); 
    const selectedLang = req.query.lang || "RU";

    let codeBranch = "main";
    if (host === "cdn-winxs.vercel.app") codeBranch = "cdn";
    if (host === "test-winxs.vercel.app") codeBranch = "test";

    // 1. ЗАГРУЗКА СЕКРЕТОВ И ПРОВЕРКА ЗАЩИТЫ
    let isAccessGranted = false;
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main" 
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        
        const symbol = secrets.symbols.find(s => rawPath.includes(s));

        if (symbol) {
            const [name, secret] = rawPath.split(symbol);
            if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
                rawPath = name; 
                isAccessGranted = true; // Секрет верный
            }
        }
    } catch (e) {
        console.error("Secrets error");
    }

    // ЕСЛИ ТЫ ХОЧЕШЬ ПОЛНУЮ ЗАЩИТУ:
    // Раскомментируй строку ниже, чтобы БЕЗ секрета вообще ничего не отдавалось:
    // if (!isAccessGranted && codeBranch === "main") return res.status(403).send("Access Denied: Secret required");

    if (rawPath === "" || rawPath === "/") rawPath = "main";

    try {
        // 2. РАЗБИВАЕМ ПУТЬ НА ПАПКУ И ФАЙЛ
        // Если вход icons/Drift, то dir = "icons", fileName = "Drift"
        const pathParts = rawPath.split('/');
        const fileNameToSearch = pathParts.pop().toLowerCase(); 
        const subDir = pathParts.join('/'); 

        // Определяем базовую папку поиска
        let searchDir = codeBranch === "main" ? "site/html" : "";
        if (subDir) {
            searchDir = searchDir ? `${searchDir}/${subDir}` : subDir;
        }

        // Получаем список файлов в нужной папке
        const { data: files } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch
        });

        // Ищем файл без учета расширения и регистра
        const targetFile = files.find(f => {
            const nameWithoutExt = f.name.split('.')[0].toLowerCase();
            return nameWithoutExt === fileNameToSearch;
        });

        if (!targetFile) throw new Error("File not found");

        // 3. ЗАГРУЗКА И ОТДАЧА
        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: targetFile.path, ref: codeBranch
        });

        const content = Buffer.from(fileData.content, 'base64');
        const ext = targetFile.name.split('.').pop().toLowerCase();

        const mimeTypes = {
            'html': 'text/html', 'css': 'text/css', 'js': 'application/javascript',
            'json': 'application/json', 'lua': 'text/plain', 'txt': 'text/plain',
            'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'svg': 'image/svg+xml', 'gif': 'image/gif', 'ico': 'image/x-icon'
        };

        const contentType = mimeTypes[ext] || 'application/octet-stream';

        if (/image|font|video/.test(contentType)) {
            return res.status(200).setHeader('Content-Type', contentType).send(content);
        } else {
            let text = content.toString('utf-8');
            return res.status(200).setHeader('Content-Type', `${contentType}; charset=utf-8`).send(text.replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        return res.status(404).send(`Error 404: File "${rawPath}" not found in ${codeBranch}`);
    }
}
