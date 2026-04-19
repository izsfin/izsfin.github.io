// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PostLoad.js — Загрузка постов
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { incrementView, formatViews } from './helper.js';

// Список всех постов
export async function loadPosts(env, headers) {
    const { results } = await env.DB.prepare(
        "SELECT id, author, title, description, views, created_at FROM posts ORDER BY created_at DESC"
    ).all();

    // Форматируем views для каждого поста
    const posts = results.map(p => ({
        ...p,
        viewsFormatted: formatViews(p.views)
    }));

    return new Response(JSON.stringify({ posts }), { headers });
}

// Один пост по ID
export async function loadPost(url, env, headers, request) {
    const id = url.searchParams.get('id');
    if (!id) {
        return new Response(JSON.stringify({ error: 'No id' }), { status: 400, headers });
    }

    const post = await env.DB.prepare(
        "SELECT * FROM posts WHERE id = ?"
    ).bind(id).first();

    if (!post) {
        return new Response(JSON.stringify({ error: 'Post not found' }), { status: 404, headers });
    }

    // Инкремент просмотров с защитой
    const views = await incrementView(env, id, request);

    return new Response(JSON.stringify({
        post: {
            ...post,
            views,
            viewsFormatted: formatViews(views)
        }
    }), { headers });
}

// Комментарии поста
export async function loadComments(url, env, headers) {
    const id = url.searchParams.get('id');
    if (!id) {
        return new Response(JSON.stringify({ error: 'No id' }), { status: 400, headers });
    }

    const { results } = await env.DB.prepare(
        "SELECT * FROM comments WHERE post_id = ? ORDER BY created_at ASC"
    ).bind(id).all();

    return new Response(JSON.stringify({ comments: results }), { headers });
}

// Добавить комментарий
export async function addComment(request, env, headers) {
    const { postId, text, token } = await request.json();

    if (!postId || !text || !token) {
        return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400, headers });
    }

    if (text.length > 2000) {
        return new Response(JSON.stringify({ error: 'Comment too long (max 2000)' }), { status: 400, headers });
    }

    const session = await env.DB.prepare(
        "SELECT username FROM sessions WHERE token = ? AND expires_at > ?"
    ).bind(token, Math.floor(Date.now() / 1000)).first();

    if (!session) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers });
    }

    await env.DB.prepare(
        "INSERT INTO comments (post_id, author, text) VALUES (?, ?, ?)"
    ).bind(postId, session.username, text).run();

    return new Response(JSON.stringify({ ok: true }), { headers });
}