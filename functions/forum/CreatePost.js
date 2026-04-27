import { getSession } from './AuthToAcc.js';
export async function createPost(request, env, headers) {
    const session = await getSession(request, env);
    if (!session) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers });
    }

    const { title, description, content, img, preview } = await request.json();

    if (!title || !content) {
        return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400, headers });
    }

    const MAX_SYMBOLS = 15000;
    if (content.length > MAX_SYMBOLS) {
        return new Response(JSON.stringify({ error: `Post too long (max ${MAX_SYMBOLS})` }), { status: 400, headers });
    }

    // preview — первые 300 символов контента если не передан явно
    const autoPreview = (preview || content.replace(/<[^>]+>/g, '').slice(0, 300)).trim();

    const id = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 40)
        + '-' + Math.random().toString(36).slice(2, 7);

    await env.DB.prepare(`
        INSERT INTO posts (id, author, title, description, content, img, preview, views)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0)
    `).bind(id, session.username, title, description || '', content, img || '', autoPreview, ).run();

    return new Response(JSON.stringify({ ok: true, id }), { headers });
}