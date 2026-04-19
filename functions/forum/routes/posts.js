import { Octokit } from "@octokit/rest";

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    
    let rawPath = url.pathname.replace(/^\/+/, "").replace(/\/+$/, "");
    const action = url.searchParams.get('action');

    const OWNER = "odesseu";
    const REPO = "hosting";
    const headers = { 
        "Content-Type": "application/json; charset=UTF-8", 
        "Access-Control-Allow-Origin": "*" 
    };

    if (rawPath === "forum" && action) {
        try {
            if (action === 'posts') {
                const { results } = await env.DB.prepare( "SELECT id, name, desc, img, author, date FROM posts ORDER BY date DESC" ).all();
                return new Response(JSON.stringify({ posts: results }), { headers }); }
            if (action === 'post' || action === 'comments') {
                const id = url.searchParams.get('id');
                const post = await env.DB.prepare("SELECT * FROM posts WHERE id = ?").bind(id).first();
                if (!post) return new Response(JSON.stringify({ error: "Post not found" }), { status: 404, headers });
                const body = action === 'comments' 
                    ? { ok: true, comments: JSON.parse(post.comments || '[]') } 
                    : { ok: true, post: { ...post, comments: JSON.parse(post.comments || '[]') } };
                return new Response(JSON.stringify(body), { headers }); }
                if (action === 'create' && request.method === 'POST') {
                const { name, desc, text, img, username, token } = await request.json();
                const session = await env.DB.prepare( "SELECT * FROM sessions WHERE token = ? AND username = ? AND expires_at > ?" ).bind(token, username, Date.now()).first();
                if (!session) { return new Response(JSON.stringify({ ok: false, error: "Unauthorized" }), { status: 401, headers }); }
                const id = name.toLowerCase().replace(/[^a-z0-9]/g, '-') + '-' + Math.random().toString(36).substring(2, 7);
                const date = new Date().toISOString();
                await env.DB.prepare( "INSERT INTO posts (id, name, desc, text, img, author, date) VALUES (?, ?, ?, ?, ?, ?, ?)" ).bind(id, name, desc, text, img || "", username, date).run();
                return new Response(JSON.stringify({ ok: true, id: id }), { headers }); }
                } catch (e) {
                  return new Response(JSON.stringify({ ok: false, error: "Server error" }), { status: 500, headers });
                 }
                }
    const pages = {
        "": "site/main.html",
        "forum": "site/forum/home.html",
        "forum/post": "site/forum/post.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    if (pages[rawPath] !== undefined) {
        try {
            const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: pages[rawPath] });
            return new Response(new TextDecoder().decode(atob(data.content)), {
                headers: { "Content-Type": "text/html; charset=UTF-8" }
            });
        } catch (e) {
            return new Response("Page not found", { status: 404 });
        }
    }
  }