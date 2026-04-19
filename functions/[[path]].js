import { Octokit } from "@octokit/rest";

function githubDecode(base64) {
    const binString = atob(base64.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binString, (m) => m.codePointAt(0));
    return new TextDecoder().decode(bytes);
}

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);

    if (url.pathname !== '/' && url.pathname.endsWith('/')) {
        return Response.redirect(url.origin + url.pathname.slice(0, -1) + url.search, 301);
    }

    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    const action = url.searchParams.get('action');
    let rawPath = url.pathname.replace(/^\/+|\/+$/g, "");

    const OWNER = "odesseu";
    const REPO = "hosting";

    if (rawPath.startsWith("site/")) {
        return context.next();
    }

    if (action) {
        const headersJSON = { "Content-Type": "application/json; charset=UTF-8", "Access-Control-Allow-Origin": "*" };
        try {
            // Показывает схему таблицы posts
            if (action === 'debug') {
                const result = await env.DB.prepare("PRAGMA table_info(posts)").all();
                return new Response(JSON.stringify(result), { headers: headersJSON });
            }

            if (action === 'posts') {
                // Читаем из D1 — колонки подправь после debug
                const result = await env.DB.prepare("SELECT * FROM posts ORDER BY rowid DESC").all();
                return new Response(JSON.stringify({ posts: result.results }), { headers: headersJSON });
            }

            if (action === 'post') {
                const id = url.searchParams.get('id');
                const result = await env.DB.prepare("SELECT * FROM posts WHERE id = ?").bind(id).first();
                if (!result) return new Response(JSON.stringify({ error: 'Not found' }), { status: 404, headers: headersJSON });
                return new Response(JSON.stringify({ post: result }), { headers: headersJSON });
            }

            if (action === 'comments') {
                const id = url.searchParams.get('id');
                const result = await env.DB.prepare("SELECT * FROM comments WHERE post_id = ? ORDER BY rowid ASC").bind(id).all();
                return new Response(JSON.stringify({ comments: result.results }), { headers: headersJSON });
            }

            if (action === 'comment' && request.method === 'POST') {
                const body = await request.json();
                const { postId, text, username } = body;
                if (!postId || !text || !username) return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400, headers: headersJSON });
                const date = new Date().toISOString().slice(0, 10);
                await env.DB.prepare("INSERT INTO comments (post_id, author, text, date) VALUES (?, ?, ?, ?)").bind(postId, username, text, date).run();
                return new Response(JSON.stringify({ ok: true }), { headers: headersJSON });
            }

            return new Response(JSON.stringify({ error: 'Action not found' }), { status: 404, headers: headersJSON });

        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: headersJSON });
        }
    }

    const pages = {
        "": "site/main.html",
        "forum": "site/forum/home.html",
        "forum/post": "site/forum/post.html",
        "docs": "site/forum/home.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    let pageKey = rawPath in pages ? rawPath : null;
    if (!pageKey) {
        for (const key of Object.keys(pages)) {
            if (key && rawPath.startsWith(key + "/")) {
                pageKey = key;
                break;
            }
        }
    }

    if (pageKey !== null) {
        try {
            const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: pages[pageKey] });
            return new Response(githubDecode(data.content), {
                headers: { "Content-Type": "text/html; charset=UTF-8" }
            });
        } catch (e) {
            return new Response(`Error: File "${pages[pageKey]}" not found in repo.`, { status: 404 });
        }
    }

    return new Response(`404: Route "${rawPath}" not recognized.`, { status: 404 });
}