import { handleAuth } from './routes/auth';
import { handleGetPosts, handleGetSinglePost } from './routes/posts';
import { handleCreatePost } from './routes/create';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const action = url.searchParams.get('action');

    // Настройка CORS
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });

    try {
      let response;
      switch (action) {
        case 'auth':
          response = await handleAuth(request);
          break;
        case 'posts':
          response = await handleGetPosts();
          break;
        case 'post':
          const id = url.searchParams.get('id');
          response = await handleGetSinglePost(id);
          break;
        case 'create':
          response = await handleCreatePost(request);
          break;
        default:
          response = Response.json({ error: 'Unknown action' }, { status: 400 });
      }

      const newResp = new Response(response.body, response);
      Object.keys(corsHeaders).forEach(k => newResp.headers.set(k, corsHeaders[k]));
      return newResp;

    } catch (err) {
      return Response.json({ error: err.message }, { status: 500, headers: corsHeaders });
    }
  }
};