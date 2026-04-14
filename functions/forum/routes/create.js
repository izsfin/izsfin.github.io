export async function handleCreatePost(req, env) {
  const { username, token, title, desc, content } = await req.json();
  
  // Проверка сессии через KV (быстрее, чем в SQL)
  const session = await env.KV.get(`session:${token}`);
  if (session !== username) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  const postId = `${username}/${title.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}`;

  await env.DB.prepare(
    "INSERT INTO posts (id, author, title, description, content) VALUES (?, ?, ?, ?, ?)"
  ).bind(postId, username, title, desc, content).run();

  return Response.json({ ok: true, id: postId });
}