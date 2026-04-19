import { hashPassword } from './lib/shared.js';

export async function handleAuth(req, env, headers) {
    const { subaction, username, password } = await req.json();

    // 1. Валидация входных данных
    if (!username || !password) {
        return new Response(JSON.stringify({ error: 'Username and password required' }), { status: 400, headers });
    }

    // 2. Хешируем пароль (соль берется из env в shared.js)
    const hashed = await hashPassword(password, env); 
    const expiresAt = Math.floor(Date.now() / 1000) + 86400; // Сессия на 24 часа (в секундах)

    // --- РЕГИСТРАЦИЯ ---
    if (subaction === 'register') {
        try {
            // Пытаемся создать пользователя
            await env.DB.prepare(
                "INSERT INTO users (username, password_hash) VALUES (?, ?)"
            ).bind(username, hashed).run();

            // Сразу создаем сессию для нового юзера, чтобы не заставлять его логиниться
            const token = crypto.randomUUID();
            await env.DB.prepare(
                "INSERT INTO sessions (token, username, expires_at) VALUES (?, ?, ?)"
            ).bind(token, username, expiresAt).run();

            return new Response(JSON.stringify({ ok: true, token, username }), { headers });

        } catch (e) {
            // Если username UNIQUE в БД, вылетит ошибка при совпадении
            return new Response(JSON.stringify({ error: 'User already exists' }), { status: 400, headers });
        }
    }
    
    // --- ЛОГИН ---
    // Ищем пользователя с таким именем и хешем
    const user = await env.DB.prepare(
        "SELECT * FROM users WHERE username = ? AND password_hash = ?"
    ).bind(username, hashed).first();
    
    if (!user) {
        return new Response(JSON.stringify({ error: 'Invalid login or password' }), { status: 401, headers });
    }

    // Создаем новую сессию
    const token = crypto.randomUUID();
    try {
        await env.DB.prepare(
            "INSERT INTO sessions (token, username, expires_at) VALUES (?, ?, ?)"
        ).bind(token, username, expiresAt).run();

        return new Response(JSON.stringify({ ok: true, token, username }), { headers });
    } catch (e) {
        return new Response(JSON.stringify({ error: 'Failed to create session' }), { status: 500, headers });
    }
}