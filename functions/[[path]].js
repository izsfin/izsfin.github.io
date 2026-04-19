import { Octokit } from "@octokit/rest";

const OWNER = "odesseu";
const REPO = "hosting";

function githubDecode(base64) {
    const binString = atob(base64.replace(/\s/g, ""));
    const bytes = Uint8Array.from(binString, (m) => m.codePointAt(0));
    return new TextDecoder().decode(bytes);
}

async function hashPassword(pass, env) {
    const salt = env.DOCS_SALT || "makito-salt-2026";
    const data = new TextEncoder().encode(pass + salt);
    const hash = await crypto.subtle.digest("SHA-512", data);
    return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, "0")).join("");
}

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const action = url.searchParams.get("action");
    const rawPath = url.pathname.replace(/^\/+|\/+$/g, "");

    const JSON_HEADERS = { 
        "Content-Type": "application/json; charset=UTF-8", 
        "Access-Control-Allow-Origin": "*" 
    };

    const ok = (data) => new Response(JSON.stringify(data), { headers: JSON_HEADERS });
    const err = (msg, status = 400) => new Response(JSON.stringify({ error: msg }), { status, headers: JSON_HEADERS });

    // ── CORS preflight ──
    if (request.method === "OPTIONS") {
        return new Response(null, { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST", "Access-Control-Allow-Headers": "Content-Type" } });
    }

    // ── API ──
    if (action) {
        try {
            // Список постов
            if (action === "posts") {
                const { results } = await env.DB.prepare(
                    "SELECT id, author, title, description, views, created_at FROM posts ORDER BY created_at DESC"
                ).all();
                return ok({ posts: results });
            }

            // Один пост
            if (action === "post") {
                const id = url.searchParams.get("id");
                if (!id) return err("No id");
                const post = await env.DB.prepare("SELECT * FROM posts WHERE id = ?").bind(id).first();
                if (!post) return err("Not found", 404);
                await env.DB.prepare("UPDATE posts SET views = views + 1 WHERE id = ?").bind(id).run();
                return ok({ post });
            }

            // Комментарии
            if (action === "comments") {
                const id = url.searchParams.get("id");
                if (!id) return err("No id");
                const { results } = await env.DB.prepare(
                    "SELECT * FROM comments WHERE post_id = ? ORDER BY created_at ASC"
                ).bind(id).all();
                return ok({ comments: results });
            }

            // Добавить комментарий
            if (action === "comment" && request.method === "POST") {
                const { postId, text, token } = await request.json();
                if (!postId || !text || !token) return err("Missing fields");
                const session = await env.DB.prepare(
                    "SELECT username FROM sessions WHERE token = ? AND expires_at > ?"
                ).bind(token, Math.floor(Date.now() / 1000)).first();
                if (!session) return err("Unauthorized", 401);
                await env.DB.prepare(
                    "INSERT INTO comments (post_id, author, text) VALUES (?, ?, ?)"
                ).bind(postId, session.username, text).run();
                return ok({ ok: true });
            }

            // Создать пост
            if (action === "create" && request.method === "POST") {
                const { title, description, content, img, token } = await request.json();
                if (!title || !token) return err("Missing fields");
                const session = await env.DB.prepare(
                    "SELECT username FROM sessions WHERE token = ? AND expires_at > ?"
                ).bind(token, Math.floor(Date.now() / 1000)).first();
                if (!session) return err("Unauthorized", 401);
                const id = title.toLowerCase().replace(/[^a-z0-9]+/g, "-") + "-" + Math.random().toString(36).slice(2, 7);
                await env.DB.prepare(
                    "INSERT INTO posts (id, author, title, description, content, views) VALUES (?, ?, ?, ?, ?, 0)"
                ).bind(id, session.username, title, description || "", content || "").run();
                return ok({ ok: true, id });
            }

            // Авторизация
            if (action === "auth" && request.method === "POST") {
                const { subaction, username, password } = await request.json();
                if (!username || !password) return err("Missing fields");
                const hashed = await hashPassword(password, env);

                if (subaction === "register") {
                    try {
                        await env.DB.prepare(
                            "INSERT INTO users (username, password_hash) VALUES (?, ?)"
                        ).bind(username, hashed).run();
                    } catch (e) {
                        return err("Username already taken");
                    }
                } else {
                    const user = await env.DB.prepare(
                        "SELECT 1 FROM users WHERE username = ? AND password_hash = ?"
                    ).bind(username, hashed).first();
                    if (!user) return err("Invalid credentials", 401);
                }

                const token = crypto.randomUUID();
                const expires = Math.floor(Date.now() / 1000) + 86400;
                await env.DB.prepare(
                    "INSERT INTO sessions (token, username, expires_at) VALUES (?, ?, ?)"
                ).bind(token, username, expires).run();
                return ok({ ok: true, token, username });
            }

            return err("Action not found", 404);

        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: JSON_HEADERS });
        }
    }

    // ── HTML СТРАНИЦЫ ──
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