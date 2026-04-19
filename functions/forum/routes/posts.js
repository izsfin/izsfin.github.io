export async function handleGetPosts(env) {
  const { results } = await env.DB.prepare( "SELECT * FROM posts ORDER BY created_at DESC LIMIT 20" ).all();
  return Response.json({ ok: true, posts: results });
}
export async function handleGetSinglePost(postId, env) {
  const post = await env.DB.prepare( "SELECT * FROM posts WHERE id = ?" ).bind(postId).first();
  if (!post) return Response.json({ error: 'Not found' }, { status: 404 });
  await env.DB.prepare( "UPDATE posts SET views = views + 1 WHERE id = ?" ).bind(postId).run();
  const comments = await env.DB.prepare( "SELECT * FROM comments WHERE post_id = ?" ).bind(postId).all();
  return Response.json({ ok: true, post, comments: comments.results || [] }); }