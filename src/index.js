const DISCORD_API = 'https://discord.com/api';
const BASE_PATH = '/dbwsender';

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);

  if (request.method === 'OPTIONS') {
    return handleOptions();
  }

  if (!url.pathname.startsWith(BASE_PATH)) {
    return new Response('Not found', { status: 404 });
  }

  const forwarded = url.pathname.slice(BASE_PATH.length);
  if (!forwarded.startsWith('/webhooks/') && !forwarded.startsWith('/channels/') && !forwarded.startsWith('/api/')) {
    return new Response('Forbidden', { status: 403 });
  }

  const targetUrl = `${DISCORD_API}${forwarded}${url.search}`;
  const proxyRequest = new Request(targetUrl, request);

  try {
    const response = await fetch(proxyRequest);
    const headers = new Headers(response.headers);
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
    headers.set('Access-Control-Allow-Headers', '*');

    const body = await response.arrayBuffer();
    return new Response(body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Worker proxy failed', message: error.message }), {
      status: 502,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': '*',
      },
    });
  }
}

function handleOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': '*',
    },
  });
}
