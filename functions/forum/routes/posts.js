export async function handleGetPosts(env, headers) {
    const { results } = await env.DB.prepare(
        "SELECT id, name, desc, img, author, date FROM posts ORDER BY date DESC"
    ).all();
    return new Response(JSON.stringify({ posts: results }), { headers });
}

export async function handleGetSinglePost(url, env, headers, action) {
    const id = url.searchParams.get('id');
    const post = await env.DB.prepare("SELECT * FROM posts WHERE id = ?").bind(id).first();
    
    if (!post) return new Response(JSON.stringify({ error: "Post not found" }), { status: 404, headers });

    const body = action === 'comments' 
        ? { ok: true, comments: JSON.parse(post.comments || '[]') } 
        : { ok: true, post: { ...post, comments: JSON.parse(post.comments || '[]') } };
    
    return new Response(JSON.stringify(body), { headers });
}