// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  helper.js — Forum utilities
//  Используется в functions/[[path]].js
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


// ─────────────────────────────────────────
//  RichText
//  parseText(raw) → HTML string
// ─────────────────────────────────────────

function esc(s) {
    return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export function parseText(raw) {
    if (!raw) return '';
    let s = String(raw);

    // Spoiler ||text||
    s = s.replace(/\|\|(.+?)\|\|/gs, (_, t) => {
        const id = 'sp' + Math.random().toString(36).slice(2);
        return `<div class="spoiler-wrap">
            <button class="spoiler-toggle" onclick="this.nextElementSibling.classList.toggle('open')">▶ Spoiler</button>
            <div class="spoiler-content">${t.trim()}</div>
        </div>`;
    });

    // Code blocks ```code```
    s = s.replace(/```([\s\S]*?)```/g, (_, c) => `<pre><code>${esc(c.trim())}</code></pre>`);

    // Inline code `code`
    s = s.replace(/`([^`]+)`/g, (_, c) => `<code>${esc(c)}</code>`);

    // Headings
    s = s.replace(/^#### (.+)/gm, (_, t) => `<h4>${t.trim()}</h4>`);
    s = s.replace(/^### (.+)/gm,  (_, t) => `<h3>${t.trim()}</h3>`);
    s = s.replace(/^## (.+)/gm,   (_, t) => `<h2>${t.trim()}</h2>`);
    s = s.replace(/^# (.+)/gm,    (_, t) => `<h1>${t.trim()}</h1>`);

    // Blockquote
    s = s.replace(/^> (.+)/gm, (_, t) => `<blockquote>${t.trim()}</blockquote>`);

    // Bold **text**
    s = s.replace(/\*\*(.+?)\*\*/g, (_, t) => `<strong>${t}</strong>`);

    // Italic *text*
    s = s.replace(/\*(.+?)\*/g, (_, t) => `<em>${t}</em>`);

    // Underline __text__
    s = s.replace(/__(.+?)__/g, (_, t) => `<u>${t}</u>`);

    // Strikethrough ~~text~~
    s = s.replace(/~~(.+?)~~/g, (_, t) => `<s>${t}</s>`);

    // Links [text](url)
    s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, t, u) =>
        `<a href="${u}" target="_blank" rel="noopener noreferrer">${t}</a>`
    );

    // Unordered list
    s = s.replace(/^(\s*)[*\-] (.+)/gm, (_, indent, item) =>
        `<li style="margin-left:${indent.length * 12}px">${item}</li>`
    );
    s = s.replace(/(<li[\s\S]*?<\/li>\n?)+/g, m => `<ul>${m}</ul>`);

    // Horizontal rule ---
    s = s.replace(/^---$/gm, '<hr>');

    // Paragraphs
    s = s.replace(/\n{2,}/g, '</p><p>');
    s = s.replace(/\n/g, '<br>');

    return `<p>${s}</p>`.replace(/<p>\s*<\/p>/g, '');
}

// Форматирует число просмотров: 1000 → 1k, 1500 → 1.5k, 1000000 → 1M
export function formatViews(n) {
    n = Number(n) || 0;
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(n % 1_000_000 === 0 ? 0 : 1).replace(/\.0$/, '') + 'M';
    if (n >= 1_000)     return (n / 1_000).toFixed(n % 1_000 === 0 ? 0 : 1).replace(/\.0$/, '') + 'k';
    return String(n);
}


// ─────────────────────────────────────────
//  ViewsCounter
//  incrementView(env, postId) → new views count
//
//  Защита: один IP/сессия не может накрутить
//  Хранит ключ  `view:{postId}:{ip}`  в D1
//  с TTL cooldown (по умолчанию 1 час)
// ─────────────────────────────────────────

const VIEW_COOLDOWN_SEC = 3600; // 1 час

export async function incrementView(env, postId, request) {
    // Получаем идентификатор посетителя (IP + User-Agent хэш)
    const ip = request.headers.get('CF-Connecting-IP')
        || request.headers.get('X-Forwarded-For')
        || 'unknown';
    const ua = request.headers.get('User-Agent') || '';

    // Простой хэш ip+ua чтобы не хранить сырой IP
    const raw = ip + ua;
    const hashBuf = await crypto.subtle.digest('SHA-1', new TextEncoder().encode(raw));
    const hash = Array.from(new Uint8Array(hashBuf)).map(b => b.toString(16).padStart(2, '0')).join('').slice(0, 16);

    const key = `${postId}:${hash}`;
    const now = Math.floor(Date.now() / 1000);

    // Проверяем была ли уже засчитана просмотр
    const existing = await env.DB.prepare(
        "SELECT viewed_at FROM view_log WHERE view_key = ?"
    ).bind(key).first();

    if (existing && (now - existing.viewed_at) < VIEW_COOLDOWN_SEC) {
        // Cooldown не прошёл — просто возвращаем текущие views
        const post = await env.DB.prepare("SELECT views FROM posts WHERE id = ?").bind(postId).first();
        return post?.views ?? 0;
    }

    // Записываем/обновляем лог просмотра
    await env.DB.prepare(
        "INSERT INTO view_log (view_key, viewed_at) VALUES (?, ?) ON CONFLICT(view_key) DO UPDATE SET viewed_at = excluded.viewed_at"
    ).bind(key, now).run();

    // Инкрементируем счётчик
    await env.DB.prepare(
        "UPDATE posts SET views = views + 1 WHERE id = ?"
    ).bind(postId).run();

    const post = await env.DB.prepare("SELECT views FROM posts WHERE id = ?").bind(postId).first();
    return post?.views ?? 0;
}


// ─────────────────────────────────────────
//  Config loader
//  loadConfig(env) → config object
//  Читает config.json из GitHub репо
// ─────────────────────────────────────────

let _configCache = null;

export async function loadConfig(octokit, owner, repo) {
    if (_configCache) return _configCache;
    try {
        const { data } = await octokit.repos.getContent({ owner, repo, path: 'site/forum/config.json' });
        const raw = atob(data.content.replace(/\s/g, ''));
        _configCache = JSON.parse(raw);
        return _configCache;
    } catch (e) {
        // Возвращаем дефолтный конфиг если файл не найден
        return getDefaultConfig();
    }
}

export function getDefaultConfig() {
    return {
        site: {
            enabled: true,
            name: "Makito Forum",
            base: "forum"
        },
        features: {
            navbar: true,
            forum: true,
            auth: true,
            verifyAuthors: false,
            authorsFile: "site/forum/authors.json"
        },
        limits: {
            maxImageSizeMB: 3,
            maxPostSymbols: 15000,
            viewCooldownSec: VIEW_COOLDOWN_SEC
        },
        paths: {
            home: "",
            post: "/post",
            create: "/create",
            auth: "/auth"
        },
        html: {
            home: "site/forum/home.html",
            post: "site/forum/post.html",
            create: "site/forum/create.html",
            auth: "site/forum/auth.html"
        },
        events: {
            enabled: false,
            file: "site/forum/events.json"
        }
    };
}