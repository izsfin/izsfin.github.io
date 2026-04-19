export async function handleGetPosts(env, headers) {
    const { results } = await env.DB.prepare(
        'SELECT id, name, "desc", img, author, date FROM posts ORDER BY date DESC'
    ).all();
    return new Response(JSON.stringify({ posts: results }), { headers });
}