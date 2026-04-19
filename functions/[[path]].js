import { Octokit } from "@octokit/rest";

function githubDecode(base64) {
    const binString = atob(base64.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binString, (m) => m.codePointAt(0));
    return new TextDecoder().decode(bytes);
}

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    const action = url.searchParams.get('action');
    
    // Очистка пути: убираем все лишние слэши в начале и конце
    let rawPath = url.pathname.replace(/^\/+|\/+$/g, "");

    const OWNER = "odesseu";
    const REPO = "hosting";

    // 1. Фикс статики (SVG, PNG, CSS)
    if (rawPath.startsWith("site/")) {
        return context.next(); 
    }

    // 2. Блок API (action)
    if (action) {
        const headersJSON = { "Content-Type": "application/json; charset=UTF-8", "Access-Control-Allow-Origin": "*" };
        try {
            if (action === 'posts') {
                const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: 'docs/index.json' });
                return new Response(githubDecode(data.content), { headers: headersJSON });
            }
            // Добавь сюда остальные action (auth, comments)
        } catch (e) {
            return new Response(JSON.stringify({ error: "GitHub API Error", details: e.message }), { status: 404, headers: headersJSON });
        }
    }

    // 3. Блок страниц
    const pages = {
        "": "site/main.html",
        "forum/": "site/forum/home.html",
        "forum/post": "site/forum/post.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    if (rawPath in pages) {
        try {
            const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: pages[rawPath] });
            return new Response(githubDecode(data.content), { 
                headers: { "Content-Type": "text/html; charset=UTF-8" } 
            });
        } catch (e) {
            return new Response(`Error: File "${pages[rawPath]}" not found in repo.`, { status: 404 });
        }
    }

    // 4. Финальный отлов (если ничего не подошло)
    return new Response(`404: Route "${rawPath}" not recognized.`, { status: 404 });
}