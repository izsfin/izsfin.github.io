const DISCORD_API = 'https://discord.com/api/v10';
export function discordAuthRedirect(env) {
    const params = new URLSearchParams({
        client_id:     env.DISCORD_CLIENT_ID,
        redirect_uri:  env.DISCORD_REDIRECT_URI,
        response_type: 'code',
        scope:         'identify',
    });
    return Response.redirect(`https://discord.com/oauth2/authorize?${params}`, 302);
}

export async function discordAuthCallback(request, env, headers) {
    const url    = new URL(request.url);
    const code   = url.searchParams.get('code');

    if (!code) {
        return new Response(JSON.stringify({ error: 'No code' }), { status: 400, headers });
    }
    const tokenRes = await fetch(`${DISCORD_API}/oauth2/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            client_id:     env.DISCORD_CLIENT_ID,
            client_secret: env.DISCORD_CLIENT_SECRET,
            grant_type:    'authorization_code',
            code,
            redirect_uri:  env.DISCORD_REDIRECT_URI,
        }),
    });

    if (!tokenRes.ok) {
        return new Response(JSON.stringify({ error: 'Token exchange failed' }), { status: 401, headers });
    }

    const { access_token } = await tokenRes.json();
    const userRes = await fetch(`${DISCORD_API}/users/@me`, {
        headers: { Authorization: `Bearer ${access_token}` },
    });
    if (!userRes.ok) {
        return new Response(JSON.stringify({ error: 'Failed to fetch Discord user' }), { status: 401, headers });
    }

    const discordUser = await userRes.json();
    const discord_id  = discordUser.id;
    const username    = discordUser.global_name || discordUser.username;
    const avatar      = discordUser.avatar
        ? `https://cdn.discordapp.com/avatars/${discord_id}/${discordUser.avatar}.png`
        : `https://cdn.discordapp.com/embed/avatars/${Number(discord_id) % 5}.png`;
    await env.DB.prepare(`
        INSERT INTO users (discord_id, username, avatar)
        VALUES (?, ?, ?)
        ON CONFLICT(discord_id) DO UPDATE SET
            username = excluded.username,
            avatar   = excluded.avatar
    `).bind(discord_id, username, avatar).run();
    const token    = crypto.randomUUID();
    const expires  = Math.floor(Date.now() / 1000) + 86400 * 7;
    await env.DB.prepare(`
        INSERT INTO sessions (token, discord_id, username, expires_at)
        VALUES (?, ?, ?, ?)
    `).bind(token, discord_id, username, expires).run();
    return new Response(null, {
        status: 302,
        headers: {
            ...headers,
            'Location':  '/',
            'Set-Cookie': `session=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${86400 * 7}`,
        },
    });
}

export async function getSession(request, env) {
    let token = null;
    const cookie = request.headers.get('Cookie') || '';
    const match  = cookie.match(/session=([^;]+)/);
    if (match) token = match[1];
    if (!token) {
        const auth = request.headers.get('Authorization') || '';
        token = auth.replace('Bearer ', '').trim() || null;
    }

    if (!token) return null;

    return await env.DB.prepare(`
        SELECT discord_id, username FROM sessions
        WHERE token = ? AND expires_at > ?
    `).bind(token, Math.floor(Date.now() / 1000)).first();
}

export async function discordLogout(request, env, headers) {
    const cookie = request.headers.get('Cookie') || '';
    const match  = cookie.match(/session=([^;]+)/);
    const token  = match?.[1];
    if (token) {
        await env.DB.prepare("DELETE FROM sessions WHERE token = ?").bind(token).run();
    }

    return new Response(null, {
        status: 302,
        headers: {
            ...headers,
            'Location':   '/auth',
            'Set-Cookie': 'session=; Path=/; Max-Age=0',
        },
    });
}