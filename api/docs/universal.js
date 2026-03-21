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

    const body = req.body || {};
    const { username, password } = body;
    const subAction = body.action || req.query.subaction;
    if (!username || !password) return res.status(400).json({ error: 'Missing fields' });
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
        return res.json({ ok: true });
    }

    if (subAction === 'login') {
        const file = await getGHFile(uPath);
        if (!file) return res.status(404).json({ error: 'User not found' });
        if (file.content.Password !== hash) return res.status(401).json({ error: 'Wrong password' });

        // Логируем IP
        const ip = req.headers['x-forwarded-for']?.split(',')[0] || 'unknown';
        const ips = file.content.IPlogins || [];
        if (!ips.includes(ip)) {
            ips.push(ip);
            file.content.IPlogins = ips;
            await putGHFile(uPath, file.content, file.sha, `docs: login ${username}`);
        }
        return res.json({ ok: true, username });
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

    const { username, password, name, desc, text, img } = req.body || {};
    if (!username || !password || !name || !desc || !text) {
        return res.status(400).json({ error: 'Missing fields' });
    }

    // Проверяем авторизацию
    const uPath = `docs/users/${username}/ui.json`;
    const uFile = await getGHFile(uPath);
    if (!uFile) return res.status(401).json({ error: 'User not found' });
    if (uFile.content.Password !== hashPassword(password)) return res.status(401).json({ error: 'Wrong password' });

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