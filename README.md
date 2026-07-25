# DBW Sender Worker

Этот каталог содержит Cloudflare Worker, который проксирует запросы к Discord API через путь `/dbwsender`.

## Как это работает

- `https://ref.izsme.workers.dev/dbwsender/webhooks/...` проксируется на `https://discord.com/api/webhooks/...`
- `https://ref.izsme.workers.dev/dbwsender/channels/...` проксируется на `https://discord.com/api/channels/...`

## Развертывание

1. Установить Wrangler:
   ```bash
   npm install -g @cloudflare/wrangler
   ```
2. Авторизоваться:
   ```bash
   wrangler login
   ```
3. Развернуть:
   ```bash
   wrangler publish
   ```

## Файлы

- `src/index.js` — основной обработчик fetch-запросов
- `wrangler.toml` — конфигурация Cloudflare Worker

## Примечание

Для `message-sender` значение proxy уже настроено на `https://ref.izsme.workers.dev/dbwsender`.
