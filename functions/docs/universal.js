import { Octokit } from '@octokit/rest';
import crypto from 'crypto';
import Redis from 'ioredis';
import { promisify } from 'util';
const pbkdf2 = promisify(crypto.pbkdf2);
const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const redis = new Redis(process.env.REDIS_URL);
const OWNER = 'misterlerp';
const REPO  = 'ML';
const BRANCH = 'main';
async function hashPassword(pass) { const salt = process.env.DOCS_SALT || 'nekoq-docs-2025'; const hash = await pbkdf2(pass, salt, 100000, 64, 'sha512'); return hash.toString('hex'); }
const BLACKLIST = ['nigger','faggot','retard','слив','leaked'];const hasBlacklist = (str) => BLACKLIST.some(w => str.toLowerCase().includes(w));

async function getGHFile(path) { try { const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path, ref: BRANCH }); return { content: JSON.parse(Buffer.from(data.content, 'base64').toString()), sha: data.sha }; } catch(e) { return null; } }
async function createOrUpdateGHFile(path, content, message) { const existing = await getGHFile(path); await octokit.repos.createOrUpdateFileContents({ owner: OWNER, repo: REPO, path, branch: BRANCH, message, sha: existing?.sha, content: Buffer.from(JSON.stringify(content, null, 2)).toString('base64') }); }
export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.status(200).end();
    const action = req.query.action;
    try {
        switch (action) {
            case 'auth':     return await handleAuth(req, res);
            case 'posts':    return await handlePosts(req, res);
            case 'post':     return await handlePost(req, res);
            case 'create':   return await handleCreate(req, res);
            default:         return res.status(400).json({ error: 'Unknown action' });
        }
    } catch(e) { console.error(e); return res.status(500).json({ error: 'Internal error' }); } }

async function handleAuth(req, res) {
    const { username, password, subaction } = req.body || {};
    if (!username || !password) return res.status(400).json({ error: 'Missing fields' });
    const uPath = `docs/users/${username}/ui.json`;
    const hashed = await hashPassword(password);
    if (subaction === 'register') {
    if (hasBlacklist(username) || username.length < 3) return res.status(400).json({ error: 'Invalid username' });
    const existing = await getGHFile(uPath); if (existing) return res.status(409).json({ error: 'Taken' });
    await createOrUpdateGHFile(uPath, { Username: username, Password: hashed, JoinDate: new Date().toISOString() }, `reg: ${username}`); }
    else { const file = await getGHFile(uPath); if (!file || file.content.Password !== hashed) return res.status(401).json({ error: 'Bad login' }); }
    const token = crypto.randomBytes(24).toString('hex'); await redis.set(`docs:session:${token}`, username, 'EX', 2592000); return res.json({ ok: true, username, token }); }
async function handlePosts(req, res) { const cached = await redis.get('docs:posts:index'); if (cached) return res.json({ posts: JSON.parse(cached) }); const indexFile = await getGHFile('docs/index.json'); const posts = indexFile?.content?.posts || []; await redis.set('docs:posts:index', JSON.stringify(posts), 'EX', 60); return res.json({ posts }); }
async function handlePost(req, res) { const id = req.query.id; if (!id) return res.status(400).json({ error: 'No ID' }); const cacheKey = `docs:post:${id}`; const cached = await redis.get(cacheKey); if (cached) return res.json({ ok: true, post: JSON.parse(cached) }); const [user, file] = id.split('/'); const data = await getGHFile(`docs/users/${user}/${file}.json`); if (!data) return res.status(404).json({ error: 'Not found' }); const postContent = data.content.Post; await redis.set(cacheKey, JSON.stringify(postContent), 'EX', 3600); return res.json({ ok: true, post: postContent }); }
async function handleCreate(req, res) { const { username, token, name, desc, text } = req.body || {}; const session = await redis.get(`docs:session:${token}`); if (session !== username) return res.status(401).json({ error: 'Auth failed' }); if (!name || name.length < 5 || hasBlacklist(name) || hasBlacklist(text)) { return res.status(400).json({ error: 'Content policy violation' }); } const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19); const filename = `${name.replace(/[^a-z0-9]/gi, '_').toLowerCase()}-${stamp}`; const id = `${username}/${filename}`;
    const newPost = { Author: username, PostName: name, PostDesc: desc, PostText: text, Date: new Date().toLocaleDateString('ru-RU') };
    await createOrUpdateGHFile(`docs/users/${username}/${filename}.json`, { Post: newPost }, `new post: ${name}`);
    const lockKey = 'docs:index:lock';
    const locked = await redis.set(lockKey, '1', 'NX', 'EX', 10);
    if (locked) { try { const indexFile = await getGHFile('docs/index.json'); const index = indexFile?.content?.posts || []; index.unshift({ id, author: username, name, desc, date: newPost.Date }); await createOrUpdateGHFile('docs/index.json', { posts: index.slice(0, 500) }, 'update index'); await redis.del('docs:posts:index'); } finally { await redis.del(lockKey); } } return res.json({ ok: true, id }); }