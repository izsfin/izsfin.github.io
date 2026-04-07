// api/docs/universal.js
import { Octokit } from '@octokit/rest';
import crypto from 'crypto';
import Redis from 'ioredis';

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const redis = new Redis(process.env.REDIS_URL);
const OWNER = 'misterlerp';
const REPO  = 'ML';
const BRANCH = 'main';

// ── Утилиты ──────────────────────────────────────────────────────────────────

// Более безопасное хеширование с использованием PBKDF2
function hashPassword(pass) {
    const salt = process.env.DOCS_SALT || 'nekoq-docs-2025';
    return crypto.pbkdf2Sync(pass, salt, 100000, 64, 'sha512').toString('hex');
}

function isValidUsername(u) {
    return /^[a-zA-Zа-яА-ЯёЁіІїЇєЄ0-9_\*\(\)\{\}\[\]\!\#\$\%\<\>\.\?\|\~]{3,32}$/.test(u);
}

function isWeakPassword(p) {
    const weak = [/^1234/, /^qwerty/i, /^password/i, /^111111/, /^000000/, /^12345678$/];
    return weak.some(r => r.test(p));
}

function isValidPassword(p) {
    return p.length >= 8 && !isWeakPassword(p);
}

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

async function createOrUpdateGHFile(path, content, message) {
    const existing = await getGHFile(path);
    await octokit.repos.createOrUpdateFileContents({
        owner: OWNER, repo: REPO, path, branch: BRANCH,
        message,
        sha: existing?.sha,
        content: Buffer.from(JSON.stringify(content, null, 2)).toString('base64')
    });
}

function nowDate() { return new Date().toLocaleDateString('ru-RU').replace(/\//g, '.'); }
function nowStamp() { return new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19); }

// ── MAIN HANDLER ─────────────────────────────────────────────────────────────

export const config = { api: { bodyParser: { sizeLimit: '5mb' } } };

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*'); 
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.status(200).end();

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
        return res.status(500).json({ error: 'Internal error: ' + e.message });
    }
}

// ── AUTH ──────────────────────────────────────────────────────────────────────

async function handleAuth(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
    const { username, password, subaction } = req.body || {};
    const mode = subaction || req.query.subaction;

    if (!username || !password) return res.status(400).json({ error: 'Missing fields' });

    const uPath = `docs/users/${username}/ui.json`;

    if (mode === 'register') {
        // Добавлена валидация
        if (!isValidUsername(username)) return res.status(400).json({ error: 'Invalid username format' });
        if (!isValidPassword(password)) return res.status(400).json({ error: 'Password too weak or short' });
        if (hasBlacklist(username)) return res.status(400).json({ error: 'Username not allowed' });

        const existing = await getGHFile(uPath);
        if (existing) return res.status(409).json({ error: 'Username taken' });

        await createOrUpdateGHFile(uPath, {
            Username: username,
            Password: hashPassword(password),
            JoinDate: [nowDate(), new Date().toLocaleTimeString()]
        }, `docs: reg ${username}`);
    } else {
        const file = await getGHFile(uPath);
        if (!file || file.content.Password !== hashPassword(password)) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
    }

    const token = crypto.randomBytes(24).toString('hex');
    await redis.set(`docs:session:${token}`, username, 'EX', 2592000).catch(()=>{});
    return res.json({ ok: true, username, token });
}

// ── POSTS LIST ────────────────────────────────────────────────────────────────

async function handlePosts(req, res) {
    // Теперь читаем из единого индекса, это в 100 раз быстрее
    const cached = await redis.get('docs:posts:index').catch(() => null);
    if (cached) return res.json({ posts: JSON.parse(cached) });

    const indexFile = await getGHFile('docs/index.json');
    const posts = indexFile?.content?.posts || [];
    
    await redis.set('docs:posts:index', JSON.stringify(posts), 'EX', 300).catch(()=>{});
    return res.json({ posts });
}

// ── SINGLE POST ───────────────────────────────────────────────────────────────

async function handlePost(req, res) {
    const id = req.query.id;
    if (!id || !id.includes('/')) return res.status(400).json({ error: 'Invalid id' });
    const [user, file] = id.split('/');
    const post = await getGHFile(`docs/users/${user}/${file}.json`);
    return post ? res.json({ ok: true, post: post.content.Post }) : res.status(404).json({ error: 'Not found' });
}

async function handleCreate(req, res) {
    const { username, token, name, desc, text, img } = req.body || {};
    if (!username || !token || !name || !text) return res.status(400).json({ error: 'Missing data' });

    const session = await redis.get(`docs:session:${token}`).catch(() => null);
    if (session !== username) return res.status(401).json({ error: 'Auth failed' });

    if (hasBlacklist(name) || hasBlacklist(text)) return res.status(400).json({ error: 'Forbidden content' });

    const stamp = nowStamp();
    const filename = `${name.replace(/[^a-z0-9]/gi, '_').toLowerCase()}-${stamp}`;
    const path = `docs/users/${username}/${filename}.json`;

    const newPost = {
        Author: username, PostName: name, PostDesc: desc,
        PostText: text, PostImg: img, Date: nowDate(), Timestamp: stamp
    };

    await createOrUpdateGHFile(path, { Post: newPost }, `docs: new post ${name}`);

    // Обновляем глобальный индекс
    const indexFile = await getGHFile('docs/index.json');
    const index = indexFile?.content?.posts || [];
    index.unshift({
        id: `${username}/${filename}`, author: username,
        name, desc, img, date: nowDate()
    });
    await createOrUpdateGHFile('docs/index.json', { posts: index.slice(0, 500) }, 'docs: update index');

    await redis.del('docs:posts:index').catch(()=>{});
    return res.json({ ok: true, id: `${username}/${filename}` });
}

// ── COMMENTS ──────────────────────────────────────────────────────────────────

async function handleComment(req, res) {
    const { postId, text, username, token } = req.body || {};
    if (!postId || !text) return res.status(400).json({ error: 'Missing fields' });

    let author = 'Anonymous';
    if (username && token) {
        const session = await redis.get(`docs:session:${token}`).catch(() => null);
        if (session === username) author = username;
    }

    const stamp = nowStamp();
    const path = `docs/comments/${postId.replace(/\//g, '-')}/${stamp}.json`;
    await createOrUpdateGHFile(path, { author, text, date: nowDate() }, 'docs: comment');

    const cKey = `docs:comments:${postId}`;
    const existing = JSON.parse(await redis.get(cKey).catch(()=>'[]') || '[]');
    existing.push({ author, text, date: nowDate() });
    await redis.set(cKey, JSON.stringify(existing), 'EX', 600).catch(()=>{});

    return res.json({ ok: true });
}

async function handleComments(req, res) {
    const postId = req.query.id;
    const cached = await redis.get(`docs:comments:${postId}`).catch(()=>null);
    return res.json({ comments: cached ? JSON.parse(cached) : [] });
}