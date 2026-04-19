import { Octokit } from "@octokit/rest";

function githubDecode(base64) {
    const binString = atob(base64.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binString, (m) => m.codePointAt(0));
    return new TextDecoder().decode(bytes);
}


if (url.pathname !== '/' && url.pathname.endsWith('/')) {
   return Response.redirect(url.origin + url.pathname.slice(0, -1) + url.search, 301);
}

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
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
            if (action === 'posts') {
                const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: 'docs/index.json' });
                return new Response(githubDecode(data.content), { headers: headersJSON });
            }
        } catch (e) {
            return new Response(JSON.stringify({ error: "GitHub API Error", details: e.message }), { status: 404, headers: headersJSON });
        }
    }

    const pages = {
        "": "site/main.html",
        "docs": "site/forum/home.html",      // ← исправлена опечатка
        "forum/post": "site/forum/post.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    // Матчим точно или по префиксу (для /forum/post/some-id)
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