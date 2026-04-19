import { handleGetPosts, handleGetSinglePost } from '/routes/posts.js';
import { handleCreatePost } from '/routes/create.js';
import { handleAuth } from '/routes/auth.js';
import { getOctokit, OWNER, REPO } from '/lib/shared.js'; // Импортируем из твоего shared.js

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const action = url.searchParams.get('action');
    const octokit = getOctokit(env);

    const headers = { 
        "Content-Type": "application/json; charset=UTF-8", 
        "Access-Control-Allow-Origin": "*" 
    };

    let rawPath = url.pathname.replace(/^\/+/, "").replace(/\/+$/, "");

    // --- API ROUTES (Forum) ---
    if (rawPath === "forum" && action) {
        try {
            if (action === 'auth') return await handleAuth(request, env, headers);
            if (action === 'posts') return await handleGetPosts(env, headers);
            if (action === 'post' || action === 'comments') return await handleGetSinglePost(url, env, headers, action);
            if (action === 'create' && request.method === 'POST') return await handleCreatePost(request, env, headers);
            
            return new Response(JSON.stringify({ error: "Action not found" }), { status: 404, headers });
        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { status: 500, headers });
        }
    }

    // --- HTML PAGES (GitHub) ---
    const pages = {
        "": "site/main.html",
        "forum": "site/forum/home.html",
        "forum/post": "site/forum/post.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    if (pages[rawPath] !== undefined) {
        try {
            const { data } = await octokit.repos.getContent({ 
                owner: OWNER, 
                repo: REPO, 
                path: pages[rawPath] 
            });
            
            return new Response(new TextDecoder().decode(atob(data.content)), {
                headers: { "Content-Type": "text/html; charset=UTF-8" }
            });
        } catch (e) {
            return new Response("Page not found", { status: 404 });
        }
    }

    return new Response("Forbidden", { status: 403 });
}