export async function handleCreatePost(request, env, headers) {
    const { name, desc, text, img, username, token } = await request.json();

    // Проверка сессии в D1
    const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE token = ? AND username = ? AND expires_at > ?"
    ).bind(token, username, Date.now()).first();

    if (!session) {
        return new Response(JSON.stringify({ ok: false, error: "Unauthorized" }), { status: 401, headers });
    }

    const id = name.toLowerCase().replace(/[^a-z0-9]/g, '-') + '-' + Math.random().toString(36).substring(2, 7);
    const date = new Date().toISOString();

    await env.DB.prepare(
        "INSERT INTO posts (id, name, desc, text, img, author, date) VALUES (?, ?, ?, ?, ?, ?, ?)"
    ).bind(id, name, desc, text, img || "", username, date).run();

    return new Response(JSON.stringify({ ok: true, id: id }), { headers });
}