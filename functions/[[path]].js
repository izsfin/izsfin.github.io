import { Octokit } from "@octokit/rest";
import { discordAuthRedirect, discordAuthCallback, discordLogout, getSession } from './forum/AuthToAcc.js';
import { createPost }                   from './forum/CreatePost.js';
import { loadPosts, loadPost, loadComments, addComment } from './forum/PostLoad.js';

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

    if (request.method === "OPTIONS") {
        return new Response(null, { headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST",
            "Access-Control-Allow-Headers": "Content-Type"
        }});
    }

    if (rawPath.startsWith("site/")) return context.next();

    if (rawPath === "auth/discord")          return discordAuthRedirect(env);
    if (rawPath === "auth/discord/callback") return discordAuthCallback(request, env, H);
    if (rawPath === "auth/logout")           return discordLogout(request, env, H);

    if (action) {
        try {
            if (action === "posts")   return loadPosts(env, H);
            if (action === "post")    return loadPost(url, env, H, request);
            if (action === "comments") return loadComments(url, env, H);
            if (action === "comment" && request.method === "POST") return addComment(request, env, H);
            if (action === "create"  && request.method === "POST") return createPost(request, env, H);

            if (action === "me") {
                const session = await getSession(request, env);
                if (!session) return new Response(JSON.stringify({ user: null }), { headers: H });
                const user = await env.DB.prepare(
                    "SELECT discord_id, username, avatar FROM users WHERE discord_id = ?"
                ).bind(session.discord_id).first();
                return new Response(JSON.stringify({ user: user || null }), { headers: H });
            }

            // NEW: verified.json endpoint
            if (action === "verified") {
                const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
                try {
                    const { data } = await octokit.repos.getContent({
                        owner: OWNER,
                        repo: REPO,
                        path: 'forum/verified.json'
                    });
                    const raw = githubDecode(data.content);
                    return new Response(raw, { headers: { ...H, "Content-Type": "application/json" } });
                } catch (e) {
                    return new Response(JSON.stringify([]), { headers: H });
                }
            }

            return new Response(JSON.stringify({ error: "Action not found" }), { status: 404, headers: H });
        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: H });
        }
    }

    // HTML routing
    let htmlFile = null;

    if (rawPath === "" || rawPath === "forum") {
        htmlFile = "forum/home.html";
    } else if (rawPath === "auth") {
        htmlFile = "forum/auth.html";
    } else if (rawPath === "catalog") {
        htmlFile = "site/catalog/catalog.html";
    } else if (rawPath === "forum/create") {
        htmlFile = "forum/create.html";
    } else if (rawPath.startsWith("forum/")) {
        htmlFile = "forum/post.html";
    }

    if (htmlFile) {
        try {
            const octokit = new Octokit({ auth: env.GITHUB_TOKEN });
            const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: htmlFile });
            return new Response(githubDecode(data.content), {
                headers: { "Content-Type": "text/html; charset=UTF-8" }
            });
        } catch (e) {
            return new Response(`File not found: ${htmlFile}`, { status: 404 });
        }
    }

    return new Response(`404: ${rawPath}`, { status: 404 });
}