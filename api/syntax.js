// api/syntax.js — Luan preprocessor endpoint
// Отдаёт Lua код препроцессора который компилирует luan → Lua

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'text/plain');

    const ua = (req.headers['user-agent'] || '').toLowerCase();
    const isRoblox = ua.includes('roblox') || ua === '' || ua === 'unknown'
        || req.headers['nekoq-access'] === 'true';

    if (!isRoblox) return res.status(403).send('-- Forbidden');

    // Lua препроцессор — возвращает таблицу с функцией compile()
    const preprocessor = `
local _M = {}

-- Таблица замен luan → Lua
-- Порядок важен: более длинные паттерны первыми
local _rules = {
    -- Функции
    {"lghg%s+\"([^\"]+)\"",  'loadstring(game:HttpGet("%1"))()'},
    {"lghg%s+'([^']+)'",     "loadstring(game:HttpGet('%1'))()"},
    {"lfyn%s+",              "local function "},
    -- Ключевые слова (целые слова через %f[%a])
    {"lsxof%f[%A]",          "elseif"},
    {"lc%f[%A]",             "local"},
    {"rnt%f[%A]",            "return"},
    {"pnt%f[%A]",            "print"},
    {"nsd%f[%A]",            "end"},
    {"ls%f[%A]",             "else"},
    {"hn%f[%A]",             "then"},
    {"of%f[%A]",             "if"},
}

function _M.compile(src)
    local result = src
    for _, rule in ipairs(_rules) do
        result = result:gsub(rule[1], rule[2])
    end
    return result
end

return _M
`;

    res.status(200).send(preprocessor.trim());
}