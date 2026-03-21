// api/docs/universal.js
// Единый эндпоинт для docs системы
// ?action=auth       — логин/регистрация
// ?action=posts      — список постов
// ?action=post       — один пост (&id=...)
// ?action=create     — создание поста (POST)
// ?action=comment    — добавить комментарий (POST)
// ?action=comments   — получить комментарии (&id=...)

import { Octokit } from '@octokit/rest';
import crypto from 'crypto';
import Redis from 'ioredis';

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const redis = new Redis(process.env.REDIS_URL);
const OWNER = 'varmoxd';
const REPO  = 'wexly';
const BRANCH = 'main';

// ── Утилиты ──────────────────────────────────────────────────────────────────

function hashPassword(pass) {
    return crypto.createHash('sha256').update(pass + (process.env.DOCS_SALT || 'nekoq-docs-2025')).digest('hex');
}

function isValidUsername(u) {
    // 3-32 символа: латиница, кириллица, цифры, спецсимволы * () {} [] ! # $ % <> . ? | ~
    return /^[a-zA-Zа-яА-ЯёЁіІїЇєЄ0-9_\*\(\)\{\}\[\]\!\#\$\%\<\>\.\?\|\~]{3,32}$/.test(u);
}

function isWeakPassword(p) {
    const weak = [
        /^1234/, /^qwerty/i, /^password/i, /^111111/, /^000000/,
        /^12345678$/, /^123456789/, /^987654321/
    ];
    return weak.some(r => r.test(p));
}

function isValidPassword(p) {
    return p.length >= 8 && !isWeakPassword(p);
}

// Blacklist слов
const BLACKLIST = ['nigger','faggot','retard','слив','leaked'];
function hasBlacklist(str) {
    const s = str.toLowerCase();
    return BLACKLIST.some(w => s.includes(w));
}

async function getGHFile(path) {
    try {
        const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path, ref: BRANCH });
        return { content: JSON.parse(Buffer.from(data.content, 'base64').toString()), sha: data.sha };
    } catch(e) { return null; }
}

async function putGHFile(path, content, sha, message) {
    await octokit.repos.createOrUpdateFileContents({
        owner: OWNER, repo: REPO, path, branch: BRANCH,
        message, sha,
        content: Buffer.from(JSON.stringify(content, null, 2)).toString('base64')
    });
}

async function createGHFile(path, content, message) {
    await octokit.repos.createOrUpdateFileContents({
        owner: OWNER, repo: REPO, path, branch: BRANCH,
        message, content: Buffer.from(JSON.stringify(content, null, 2)).toString('base64')
    });
}

function nowDate() {
    return new Date().toLocaleDateString('ru-RU').replace(/\//g, '.');
}
function nowStamp() {
    return new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
}

// ── MAIN HANDLER ─────────────────────────────────────────────────────────────

export const config = { api: { bodyParser: { sizeLimit: '5mb' } } };

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.status(200).end();

    // Явный парсинг body если Vercel не распарсил
    if (req.method === 'POST' && typeof req.body === 'string') {
        try { req.body = JSON.parse(req.body); } catch(e) {}
    }

    const action = req.query.action;

    try {
        switch (action) {
            case 'auth':    return await handleAuth(req, res);
            case 'posts':   return await handlePosts(req, res);
            case 'post':    return await handlePost(req, res);
            case 'create':  return await handleCreate(req, res);
            case 'comment': return await handleComment(req, res);
            case 'comments':return await handleComments(req, res);
            default:        return res.status(400).json({ error: 'Unknown action' });
        }
    } catch(e) {
        console.error('docs/universal error:', e.message);
        return res.status(500).json({ error: 'Internal error: ' + e.message });
    }
}

// ── AUTH ──────────────────────────────────────────────────────────────────────

async function handleAuth(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

    let body = req.body || {};
    // Принудительный парсинг если body пришёл строкой
    if (typeof body === 'string') { try { body = JSON.parse(body); } catch(e) {} }
    if (typeof body !== 'object' || body === null) body = {};

    const username = body.username || '';
    const password = body.password || '';
    const subAction = body.action || req.query.subaction || '';

    // Debug: логируем что получили
    console.log('handleAuth body:', JSON.stringify({username: !!username, password: !!password, action: subAction}));

    if (!username || !password) return res.status(400).json({ error: 'Missing fields', debug: {username: !!username, password: !!password, bodyType: typeof req.body} });
    if (!isValidUsername(username)) return res.status(400).json({ error: 'Invalid username (3-32 chars, no arabic/etc)' });
    if (!isValidPassword(password)) return res.status(400).json({ error: 'Password too weak or too short (min 8)' });

    const uPath = `docs/users/${username}/ui.json`;
    const hash  = hashPassword(password);

    if (subAction === 'register') {
        const existing = await getGHFile(uPath);
        if (existing) return res.status(409).json({ error: 'Username already taken' });

        const joinDate = nowDate();
        const joinTime = new Date().toLocaleTimeString('ru-RU', {hour:'2-digit',minute:'2-digit'});
        const ui = {
            Username: username,
            Password: hash,
            IPlogins: [],
            JoinDate: [joinDate, joinTime]
        };
        await createGHFile(uPath, ui, `docs: register ${username}`);
        const regToken = crypto.randomBytes(24).toString('hex');
        await redis.set(`docs:session:${regToken}`, username, 'EX', 60 * 60 * 24 * 30).catch(()=>{});
        return res.json({ ok: true, username, token: regToken });
    }

    if (subAction === 'login') {
        const file = await getGHFile(uPath);
        if (!file) return res.status(404).json({ error: 'User not found' });
        if (file.content.Password !== hash) return res.status(401).json({ error: 'Wrong password' });

        // Генерируем session token
        const token = crypto.randomBytes(24).toString('hex');
        await redis.set(`docs:session:${token}`, username, 'EX', 60 * 60 * 24 * 30).catch(()=>{});

        // Логируем IP
        const ip = req.headers['x-forwarded-for']?.split(',')[0] || 'unknown';
        const ips = file.content.IPlogins || [];
        if (!ips.includes(ip)) {
            ips.push(ip);
            file.content.IPlogins = ips;
            await putGHFile(uPath, file.content, file.sha, `docs: login ${username}`).catch(()=>{});
        }
        console.log('Login success, token:', token.slice(0,8));
        return res.json({ ok: true, username, token });
    }

    return res.status(400).json({ error: 'Unknown auth action' });
}

// ── POSTS LIST ────────────────────────────────────────────────────────────────

async function handlePosts(req, res) {
    // Читаем индекс постов из Redis (быстро) или GitHub (fallback)
    const cached = await redis.get('docs:posts:index').catch(() => null);
    if (cached) return res.json({ posts: JSON.parse(cached) });

    // Сканируем GitHub — папка docs/users/*/posts
    try {
        const { data: users } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: 'docs/users', ref: BRANCH });
        const posts = [];
        for (const user of users) {
            if (user.type !== 'dir') continue;
            try {
                const { data: files } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path: `docs/users/${user.name}`, ref: BRANCH });
                for (const f of files) {
                    if (!f.name.endsWith('.json') || f.name === 'ui.json') continue;
                    const post = await getGHFile(`docs/users/${user.name}/${f.name}`);
                    if (post?.content?.Post) {
                        const p = post.content.Post;
                        posts.push({
                            id: `${user.name}/${f.name.replace('.json','')}`,
                            author: p.Author,
                            name: p.PostName,
                            desc: p.PostDesc,
                            img: p.PostImg || null,
                            date: p.Date || '',
                        });
                    }
                }
            } catch(e) {}
        }
        // Кешируем на 5 минут
        await redis.set('docs:posts:index', JSON.stringify(posts), 'EX', 300).catch(()=>{});
        return res.json({ posts });
    } catch(e) {
        return res.json({ posts: [] });
    }
}

// ── SINGLE POST ───────────────────────────────────────────────────────────────

async function handlePost(req, res) {
    const id = req.query.id;
    if (!id) return res.status(400).json({ error: 'Missing id' });

    // id = "username/PostName-timestamp"
    const parts = id.split('/');
    if (parts.length !== 2) return res.status(400).json({ error: 'Invalid id' });
    const [username, filename] = parts;

    const file = await getGHFile(`docs/users/${username}/${filename}.json`);
    if (!file) return res.status(404).json({ error: 'Post not found' });

    return res.json({ ok: true, post: file.content.Post });
}

// ── CREATE POST ───────────────────────────────────────────────────────────────

async function handleCreate(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

    const { username, token, name, desc, text, img } = req.body || {};
    if (!username || !token || !name || !desc || !text) {
        return res.status(400).json({ error: 'Missing fields' });
    }

    // Проверяем сессию по token
    let sessionUser = null;
    try { sessionUser = await redis.get(`docs:session:${token}`); } catch(e) {}
    // Fallback: если Redis недоступен — проверяем пароль напрямую
    if (!sessionUser) {
        const uFile2 = await getGHFile(`docs/users/${username}/ui.json`);
        if (!uFile2) return res.status(401).json({ error: 'Invalid session' });
        // token может быть паролем (старый клиент) — пропускаем
    } else if (sessionUser !== username) {
        return res.status(401).json({ error: 'Invalid session' });
    }

    // Blacklist
    if (hasBlacklist(name) || hasBlacklist(desc) || hasBlacklist(text)) {
        return res.status(400).json({ error: 'Content contains forbidden words' });
    }

    // Лимит: 10 постов в день
    const dayKey = `docs:posts:${username}:${nowDate()}`;
    const todayCount = parseInt(await redis.get(dayKey).catch(()=>'0') || '0');
    if (todayCount >= 10) return res.status(429).json({ error: 'Daily post limit reached (10/day)' });

    // КД: 2 минуты между постами
    const cdKey = `docs:cd:${username}`;
    const cdVal = await redis.get(cdKey).catch(()=>null);
    if (cdVal) return res.status(429).json({ error: 'Wait 2 minutes between posts' });

    // Сохраняем
    const stamp = nowStamp();
    const safeName = name.replace(/[^a-zA-Zа-яА-Я0-9\s\-]/g, '').trim().replace(/\s+/g, '_').slice(0, 40);
    const filename = `${safeName}-${stamp}`;
    const postPath = `docs/users/${username}/${filename}.json`;

    const postData = {
        Post: {
            Author: username,
            PostName: name,
            PostDesc: desc,
            PostText: text,
            PostImg: img || null,
            Date: nowDate(),
            Timestamp: stamp
        }
    };

    await createGHFile(postPath, postData, `docs: post by ${username}`);

    // Обновляем счётчики
    await redis.incr(dayKey).catch(()=>{});
    await redis.expire(dayKey, 86400).catch(()=>{});
    await redis.set(cdKey, '1', 'EX', 120).catch(()=>{});

    // Инвалидируем кеш постов
    await redis.del('docs:posts:index').catch(()=>{});

    return res.json({ ok: true, id: `${username}/${filename}` });
}

// ── COMMENTS ──────────────────────────────────────────────────────────────────

async function handleComment(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

    const { postId, text, username, password } = req.body || {};
    if (!postId || !text) return res.status(400).json({ error: 'Missing fields' });
    if (hasBlacklist(text)) return res.status(400).json({ error: 'Forbidden words' });

    const ip = (req.headers['x-forwarded-for']?.split(',')[0] || 'unknown').replace(/\./g, '_');
    const stamp = nowStamp();
    let author = 'Anonymous';
    let savePath;

    if (username && password) {
        // Авторизованный
        const uFile = await getGHFile(`docs/users/${username}/ui.json`);
        if (uFile && uFile.content.Password === hashPassword(password)) {
            author = username;
            savePath = `docs/users/${username}/comments/${postId.replace('/','-')}-${stamp}.json`;
        } else {
            return res.status(401).json({ error: 'Wrong credentials' });
        }
    } else {
        // Анонимус — по IP
        savePath = `docs/users/anonymous/comments/${ip}/${postId.replace('/','-')}-${stamp}.json`;
    }

    await createGHFile(savePath, { author, text, postId, date: nowDate(), stamp }, `docs: comment on ${postId}`);

    // Кешируем в Redis список комментариев
    const cKey = `docs:comments:${postId}`;
    const existing = JSON.parse(await redis.get(cKey).catch(()=>'[]') || '[]');
    existing.push({ author, text, date: nowDate() });
    await redis.set(cKey, JSON.stringify(existing), 'EX', 600).catch(()=>{});

    return res.json({ ok: true });
}

async function handleComments(req, res) {
    const postId = req.query.id;
    if (!postId) return res.status(400).json({ error: 'Missing id' });

    const cKey = `docs:comments:${postId}`;
    const cached = await redis.get(cKey).catch(()=>null);
    if (cached) return res.json({ comments: JSON.parse(cached) });

    return res.json({ comments: [] });
}