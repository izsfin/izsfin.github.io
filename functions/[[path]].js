import { Octokit } from "@octokit/rest";
import { authToAcc }                    from './forum/AuthToAcc.js';
import { createPost }                   from './forum/CreatePost.js';
import { loadPosts, loadPost, loadComments, addComment } from './forum/PostLoad.js';
import { attachVerified }               from './forum/VerifiedAccounts.js';

const OWNER = "odesseu";
const REPO  = "hosting";

function githubDecode(base64) {
    const binString = atob(base64.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binString, m => m.codePointAt(0));
    return new TextDecoder().decode(bytes);
}

export async function onRequest(context) {
    const { request, env } = context;
    const url    = new URL(request.url);
    const action = url.searchParams.get("action");
    let rawPath  = url.pathname.replace(/^\/+|\/+$/g, "");

    const H = {
        "Content-Type": "application/json; charset=UTF-8",
        "Access-Control-Allow-Origin": "*"
    };

    // CORS preflight
    if (request.method === "OPTIONS") {
        return new Response(null, { headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST",
            "Access-Control-Allow-Headers": "Content-Type"
        }});
    }

    // Статика
    if (rawPath.startsWith("site/")) return context.next();

    // ── API ──
    if (action) {
        try {
            const octokit = new Octokit({ auth: env.GITHUB_TOKEN });

            if (action === "posts") {
                const res  = await loadPosts(env, H);
                const data = await res.json();
                // Добавляем verified к каждому посту
                data.posts = await attachVerified(data.posts, 'author', octokit, OWNER, REPO);
                return new Response(JSON.stringify(data), { headers: H });
            }

            if (action === "post") {
                const res  = await loadPost(url, env, H, request);
                const data = await res.json();
                if (data.post) {
                    const [withV] = await attachVerified([data.post], 'author', octokit, OWNER, REPO);
                    data.post = withV;
                }
                return new Response(JSON.stringify(data), { headers: H });
            }

            if (action === "comments") {
                const res  = await loadComments(url, env, H);
                const data = await res.json();
                if (data.comments) {
                    data.comments = await attachVerified(data.comments, 'author', octokit, OWNER, REPO);
                }
                return new Response(JSON.stringify(data), { headers: H });
            }

            if (action === "comment"  && request.method === "POST") return addComment(request, env, H);
            if (action === "create"   && request.method === "POST") return createPost(request, env, H);
            if (action === "auth"     && request.method === "POST") return authToAcc(request, env, H);

            return new Response(JSON.stringify({ error: "Action not found" }), { status: 404, headers: H });

        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: H });
        }
    }

    // ── HTML страницы ──
    const pages = {
        "":            "site/forum/home.html",
        "forum":       "site/forum/home.html",
        "forum/post":  "site/forum/post.html",
        "create/":     "site/forum/create.html",
        "auth":        "site/forum/auth.html",
        "catalog":     "site/catalog/catalog.html"
    };

    let pageKey = rawPath in pages ? rawPath : null;
    if (!pageKey) {
        for (const key of Object.keys(pages)) {
            if (key && rawPath.startsWith(key + "/")) { pageKey = key; break; }
        }
    }

    if (pageKey !== null) {
        try {
            const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
            const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: pages[pageKey] });
            return new Response(githubDecode(data.content), {
                headers: { "Content-Type": "text/html; charset=UTF-8" }
            });
        } catch (e) {
            return new Response(`File not found: ${pages[pageKey]}`, { status: 404 });
        }
    }

    return new Response(`404: ${rawPath}`, { status: 404 });
}