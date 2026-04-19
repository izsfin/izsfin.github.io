import { Octokit } from "@octokit/rest";
export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
    let rawPath = url.pathname.replace(/^\/+/, "").replace(/\/+$/, "");
    const action = url.searchParams.get('action');
    
    const OWNER = "odesseu";
    const REPO = "hosting";

    if (rawPath === "forum" && action) { const headers = {  "Content-Type": "application/json; charset=UTF-8", "Access-Control-Allow-Origin": "*"  };
    try { if (action === 'posts') { const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: 'docs/index.json' }); return new Response(atob(data.content), { headers }); } if (action === 'post' || action === 'comments') { const id = url.searchParams.get('id'); const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: `docs/${id}.json` }); const content = JSON.parse(atob(data.content)); const body = action === 'comments' ? { ok: true, comments: content.comments || [] } : { ok: true, post: content }; return new Response(JSON.stringify(body), { headers }); } }
    catch (e) { return new Response(JSON.stringify({ error: "Data not found" }), { status: 404, headers }); } }
    const pages = {
        "": "site/main.html",
        "forum": "site/forum/home.html",
        "forum/post": "site/forum/post.html",
        "auth": "site/auth.html",
        "catalog": "site/catalog/catalog.html"
    };

    if (pages[rawPath] !== undefined) { try { const { data } = await octokit.repos.getContent({  owner: OWNER, repo: REPO, path: pages[rawPath] }); return new Response(new TextDecoder().decode(atob(data.content)), { headers: { "Content-Type": "text/html; charset=UTF-8" } }); } catch (e) { return new Response("Page not found in repository", { status: 404 }); } } return new Response("Access Denied: Use specific subdomains for file access.", { status: 403 }); }