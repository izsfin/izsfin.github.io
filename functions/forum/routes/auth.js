import { handleGetPosts, handleGetSinglePost } from './routes/posts.js';
import { handleCreatePost } from './routes/create.js';
import { handleAuth } from './routes/auth.js';

export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);
    const action = url.searchParams.get('action');

    const headers = { 
        "Content-Type": "application/json; charset=UTF-8", 
        "Access-Control-Allow-Origin": "*" 
    };

    try {
        // Роут авторизации (login / register)
        if (action === 'auth' && request.method === 'POST') {
            return await handleAuth(request, env, headers);
        }

        if (action === 'posts') return await handleGetPosts(env, headers);
        if (action === 'post' || action === 'comments') return await handleGetSinglePost(url, env, headers, action);
        
        if (action === 'create' && request.method === 'POST') {
            return await handleCreatePost(request, env, headers);
        }
        
        return new Response(JSON.stringify({ error: "Action not found" }), { status: 404, headers });
    } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500, headers });
    }
}