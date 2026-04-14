export async function handleAuth(req, env) {
  const { subaction, username, password } = await req.json();
  const hashed = await hashPassword(password); // функция хеширования из lib

  if (subaction === 'register') {
    try {
      await env.DB.prepare(
        "INSERT INTO users (username, password_hash) VALUES (?, ?)"
      ).bind(username, hashed).run();
      
      const token = crypto.randomUUID();
      await env.KV.put(`session:${token}`, username, { expirationTtl: 86400 });
      return Response.json({ ok: true, token, username });
    } catch (e) {
      return Response.json({ error: 'User already exists' }, { status: 400 });
    }
  }
  
  // Логика логина через SQL
  const user = await env.DB.prepare(
    "SELECT * FROM users WHERE username = ? AND password_hash = ?"
  ).bind(username, hashed).first();

  if (!user) return Response.json({ error: 'Invalid login' }, { status: 401 });

  const token = crypto.randomUUID();
  await env.KV.put(`session:${token}`, username, { expirationTtl: 86400 });
  return Response.json({ ok: true, token, username });
}