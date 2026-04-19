// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  VerifiedAccounts.js
//  Загружает список верифицированных юзеров
//  из VerifiedAccounts.json (только username)
//  и возвращает Set для быстрой проверки
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// VerifiedAccounts.json формат:
// ["username1", "username2", "username3"]

let _cache = null;
let _cacheTime = 0;
const CACHE_TTL_SEC = 300; // обновляем кэш каждые 5 минут

export async function getVerifiedSet(octokit, owner, repo) {
    const now = Math.floor(Date.now() / 1000);

    if (_cache && (now - _cacheTime) < CACHE_TTL_SEC) {
        return _cache;
    }

    try {
        const { data } = await octokit.repos.getContent({
            owner, repo,
            path: 'site/forum/VerifiedAccounts.json'
        });
        const list = JSON.parse(atob(data.content.replace(/\s/g, '')));
        _cache = new Set(Array.isArray(list) ? list.map(u => String(u).toLowerCase()) : []);
        _cacheTime = now;
    } catch (e) {
        // Файл не найден или ошибка — возвращаем пустой Set
        _cache = new Set();
        _cacheTime = now;
    }

    return _cache;
}

// Проверяет верифицирован ли конкретный юзер
export async function isVerified(username, octokit, owner, repo) {
    const set = await getVerifiedSet(octokit, owner, repo);
    return set.has(String(username).toLowerCase());
}

// Добавляет к массиву постов/комментариев поле verified
export async function attachVerified(items, usernameField = 'author', octokit, owner, repo) {
    const set = await getVerifiedSet(octokit, owner, repo);
    return items.map(item => ({
        ...item,
        verified: set.has(String(item[usernameField] || '').toLowerCase())
    }));
}