import { handleAuth } from './routes/auth.js';
import { handleCreatePost } from './routes/create.js';
import { handleGetPosts, handleGetSinglePost } from './routes/posts.js';
export async function onRequest(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  const action = url.searchParams.get('action');
  if (action === 'auth') return await handleAuth(request, env);
  if (action === 'create') return await handleCreatePost(request, env);
  if (action === 'posts') return await handleGetPosts(env);
  if (action === 'post') return await handleGetSinglePost(url.searchParams.get('id'), env);
  return new Response("Not Found", { status: 404 });
}