export async function handleCreatePost(req, env) {
  const { username, token, title, desc, content } = await req.json();
  const session = await env.DB.prepare( "SELECT username FROM sessions WHERE token = ? AND expires_at > ?" ).bind(token, Math.floor(Date.now() / 1000)).first();
  if (!session || session.username !== username) { return Response.json({ error: 'Unauthorized' }, { status: 401 }); }
  const slug = title.toLowerCase().trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
  const postId = `${username}/${slug}-${Date.now()}`;
  await env.DB.prepare( "INSERT INTO posts (id, author, title, description, content) VALUES (?, ?, ?, ?, ?)" ).bind(postId, username, title, desc, content).run();
  return Response.json({ ok: true, id: postId });
}