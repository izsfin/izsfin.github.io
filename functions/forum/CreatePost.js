// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CreatePost.js — Создание поста
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export async function createPost(request, env, headers) {
    const { title, description, content, img, token } = await request.json();

    if (!title || !content || !token) {
        return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400, headers });
    }

    // Проверка сессии
    const session = await env.DB.prepare(
        "SELECT username FROM sessions WHERE token = ? AND expires_at > ?"
    ).bind(token, Math.floor(Date.now() / 1000)).first();

    if (!session) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers });
    }

    // Лимит символов
    const MAX_SYMBOLS = 15000;
    if (content.length > MAX_SYMBOLS) {
        return new Response(JSON.stringify({ error: `Post too long (max ${MAX_SYMBOLS} symbols)` }), { status: 400, headers });
    }

    // Генерация ID
    const id = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 40)
        + '-' + Math.random().toString(36).slice(2, 7);

    await env.DB.prepare(
        "INSERT INTO posts (id, author, title, description, content, img, views) VALUES (?, ?, ?, ?, ?, ?, 0)"
    ).bind(id, session.username, title, description || '', content, img || '').run();

    return new Response(JSON.stringify({ ok: true, id }), { headers });
}