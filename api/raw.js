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

    // 1. ПОЛУЧАЕМ СЕКРЕТЫ (Берем из main всегда)
    let secrets = { secret_word: "night", symbols: ["@", "~"] }; // Дефолт на случай ошибки
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: "api/core/secrets.json", ref: "main"
        });
        secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
    } catch (e) {}

    // 2. ПРОВЕРКА СЕКРЕТА
    const symbol = secrets.symbols.find(s => rawPath.includes(s));
    if (symbol) {
        const [name, secret] = rawPath.split(symbol);
        if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
            rawPath = name; 
        } else {
            return res.status(403).send("Wrong secret");
        }
    } else {
        // Если символа секрета нет в ссылке — СУКА, НЕ ДАЕМ ФАЙЛ (если нужна защита)
        // Если хочешь чтобы БЕЗ секрета пускало — закомментируй строку ниже
        return res.status(403).send("Secret required (e.g. filename@night)");
    }

    if (rawPath === "" || rawPath === "/") rawPath = "main";

    try {
        // 3. ПОИСК ФАЙЛА
        // Разбиваем путь, например: icons/Drift -> папка "icons", файл "Drift"
        const parts = rawPath.split('/');
        const fileName = parts.pop().toLowerCase();
        const subDir = parts.join('/');

        // Где ищем? В main это site/html, в cdn — корень
        let searchPath = codeBranch === "main" ? "site/html" : "";
        if (subDir) searchPath = searchPath ? `${searchPath}/${subDir}` : subDir;

        const { data: folderContent } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: searchPath, ref: codeBranch
        });

        // Ищем файл в списке
        const target = folderContent.find(f => f.name.split('.')[0].toLowerCase() === fileName);

        if (!target) return res.status(404).send(`File ${fileName} not found in ${searchPath}`);

        // 4. ГРУЗИМ КОНТЕНТ ФАЙЛА
        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: target.path, ref: codeBranch
        });

        const buffer = Buffer.from(fileData.content, 'base64');
        const ext = target.name.split('.').pop().toLowerCase();

        const mimes = {
            'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'svg': 'image/svg+xml', 'gif': 'image/gif', 'html': 'text/html',
            'css': 'text/css', 'js': 'application/javascript', 'json': 'application/json',
            'lua': 'text/plain', 'txt': 'text/plain'
        };

        const type = mimes[ext] || 'application/octet-stream';

        res.setHeader('Content-Type', type);
        
        if (type.includes('image') || type.includes('octet')) {
            return res.status(200).send(buffer);
        } else {
            let text = buffer.toString('utf-8');
            return res.status(200).send(text.replace(/{{LANG}}/g, selectedLang));
        }

    } catch (err) {
        return res.status(404).send("Error: " + err.message);
    }
}
