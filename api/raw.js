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

    // 1. ЗАГРУЗКА СЕКРЕТОВ ИЗ РЕПОЗИТОРИЯ
    try {
        const { data: sData } = await octokit.repos.getContent({
            owner: OWNER, 
            repo: REPO, 
            path: "api/core/secrets.json", 
            ref: "main" 
        });
        const secrets = JSON.parse(Buffer.from(sData.content, 'base64').toString('utf-8'));
        
        // Ищем символ (@ или ~)
        const symbol = secrets.symbols.find(s => rawPath.includes(s));

        if (symbol) {
            const [name, secret] = rawPath.split(symbol);
            // Проверка секретного слова (регистронезависимо)
            if (secret && secret.toLowerCase() === secrets.secret_word.toLowerCase()) {
                rawPath = name; 
            } else {
                return res.status(403).send("Forbidden: Invalid Secret");
            }
        }
    } catch (e) {
        console.error("Secrets config not found or invalid");
    }

    // Если путь пустой, по умолчанию отдаем main
    if (rawPath === "" || rawPath === "/") rawPath = "main";

    try {
        // 2. ПОИСК ФАЙЛА (БЕЗ РЕГИСТРА И РАСШИРЕНИЯ)
        const searchDir = codeBranch === "main" ? "site/html" : "";
        
        const { data: files } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: searchDir, ref: codeBranch
        });

        const targetFile = files.find(f => {
            const nameWithoutExt = f.name.split('.')[0].toLowerCase();
            return nameWithoutExt === rawPath.toLowerCase();
        });

        if (!targetFile) throw new Error("File not found");

        // 3. ЗАГРУЗКА КОНТЕНТА
        const { data: fileData } = await octokit.repos.getContent({
            owner: OWNER, repo: REPO, path: targetFile.path, ref: codeBranch
        });

        const content = Buffer.from(fileData.content, 'base64');
        const ext = targetFile.name.split('.').pop().toLowerCase();

        // ОГРОМНЫЙ СПИСОК РАСШИРЕНИЙ
        const mimeTypes = {
            // Текст и код
            'html': 'text/html',
            'css': 'text/css',
            'js': 'application/javascript',
            'json': 'application/json',
            'lua': 'text/plain',
            'txt': 'text/plain',
            'md': 'text/markdown',
            'xml': 'application/xml',
            // Изображения
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'svg': 'image/svg+xml',
            'gif': 'image/gif',
            'ico': 'image/x-icon',
            'webp': 'image/webp',
            // Шрифты
            'woff': 'font/woff',
            'woff2': 'font/woff2',
            'ttf': 'font/ttf',
            'otf': 'font/otf',
            // Видео/Аудио
            'mp4': 'video/mp4',
            'mp3': 'audio/mpeg',
            'wav': 'audio/wav',
            'ogg': 'audio/ogg'
        };

        const contentType = mimeTypes[ext] || 'application/octet-stream';

        // Если это картинка, шрифт или видео — отдаем как есть (бинарно)
        const isBinary = /image|font|video|audio/.test(contentType) || contentType === 'application/octet-stream';

        if (isBinary) {
            return res.status(200)
                .setHeader('Content-Type', contentType)
                .setHeader('Cache-Control', 'public, max-age=3600')
                .send(content);
        } else {
            // Если текст, применяем замену {{LANG}}
            let text = content.toString('utf-8');
            return res.status(200)
                .setHeader('Content-Type', `${contentType}; charset=utf-8`)
                .send(text.replace(/{{LANG}}/g, selectedLang));
        }

    } catch (error) {
        return res.status(404).send(`Error 404: File "${rawPath}" not found in branch "${codeBranch}"`);
    }
}
