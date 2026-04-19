import { Octokit } from "@octokit/rest";

// Вспомогательная функция для корректного декодирования UTF-8 из Base64
function githubDecode(base64) {
    const binString = atob(base64.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binString, (m) => m.codePointAt(0));
    return new TextDecoder().decode(bytes);
}

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    
    // Нормализуем путь: убираем слэши и приводим к нижнему регистру
    let rawPath = url.pathname.replace(/^\/+/, "").replace(/\/+$/, "").toLowerCase();
    const action = url.searchParams.get('action');
    if (rawPath.startsWith("site/")) {
        return context.next(); 
    }
    const OWNER = "odesseu";
    const REPO = "hosting";
    const headersJSON = { 
        "Content-Type": "application/json; charset=UTF-8", 
        "Access-Control-Allow-Origin": "*" 
    };

    // ── БЛОК API (ДАННЫЕ) ──
    if (rawPath === "forum" && action) {
        try {
            if (action === 'posts') {
                const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: 'docs/index.json' });
                return new Response(githubDecode(data.content), { headers: headersJSON });
            }

            if (action === 'post' || action === 'comments') {
                const id = url.searchParams.get('id');
                if (!id) throw new Error("Missing ID");

                const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: `docs/${id}.json` });
                const content = JSON.parse(githubDecode(data.content));
                
                const body = action === 'comments' 
                    ? { ok: true, comments: content.comments || [] } 
                    : { ok: true, post: content };

                return new Response(JSON.stringify(body), { headers: headersJSON });
            }
        } catch (e) {
            return new Response(JSON.stringify({ error: "Data not found", details: e.message }), { status: 404, headers: headersJSON });
        }
    }

    const pages = {
        "": "site/main.html",
        "forum": "site/forum/home.html",
        "forum/post": "site/forum/post.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    if (rawPath in pages) {
        try {
            const { data } = await octokit.repos.getContent({ 
                owner: OWNER, 
                repo: REPO, 
                path: pages[rawPath] 
            });

            return new Response(githubDecode(data.content), { 
                headers: { "Content-Type": "text/html; charset=UTF-8" } 
            });
        } catch (e) {
            return new Response(`[404] Page "${pages[rawPath]}" not found in repository.`, { status: 404 });
        }
    }

    // Если путь не найден в API и не найден в Pages
    return new Response("Access Denied: Route not found.", { status: 403 });
}