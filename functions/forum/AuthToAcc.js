// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  AuthToAcc.js — Авторизация / Регистрация
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function hashPassword(password, env) {
    const salt = env.DOCS_SALT || 'makito-salt-2026';
    const data = new TextEncoder().encode(password + salt);
    const hash = await crypto.subtle.digest('SHA-512', data);
    return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
}

export async function authToAcc(request, env, headers) {
    const { subaction, username, password } = await request.json();

    if (!username || !password) {
        return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400, headers });
    }

    if (username.length < 3 || username.length > 32) {
        return new Response(JSON.stringify({ error: 'Username must be 3–32 chars' }), { status: 400, headers });
    }

    const hashed = await hashPassword(password, env);
    const expires = Math.floor(Date.now() / 1000) + 86400; // 24 часа

    // ── РЕГИСТРАЦИЯ ──
    if (subaction === 'register') {
        if (password.length < 8) {
            return new Response(JSON.stringify({ error: 'Password min 8 chars' }), { status: 400, headers });
        }
        try {
            await env.DB.prepare(
                "INSERT INTO users (username, password_hash) VALUES (?, ?)"
            ).bind(username, hashed).run();
        } catch (e) {
            return new Response(JSON.stringify({ error: 'Username already taken' }), { status: 400, headers });
        }
    } else {
        // ── ЛОГИН ──
        const user = await env.DB.prepare(
            "SELECT 1 FROM users WHERE username = ? AND password_hash = ?"
        ).bind(username, hashed).first();

        if (!user) {
            return new Response(JSON.stringify({ error: 'Invalid login or password' }), { status: 401, headers });
        }
    }

    // Создаём сессию
    const token = crypto.randomUUID();
    await env.DB.prepare(
        "INSERT INTO sessions (token, username, expires_at) VALUES (?, ?, ?)"
    ).bind(token, username, expires).run();

    return new Response(JSON.stringify({ ok: true, token, username }), { headers });
}