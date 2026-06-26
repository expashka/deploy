# sites-deploy

Универсальный deploy-скрипт для статических и Docker Compose проектов.
Один скрипт на все сайты на сервере — настройки в `.deploy.env` каждого проекта,
проектные особенности — через хуки в `.deploy/`.

## Установка (один раз на сервер)

```bash
curl -fsSL https://raw.githubusercontent.com/expashka/deploy/main/install.sh | bash
```

Кладёт исполняемый файл в `/usr/local/bin/sites-deploy`. Обновление:

```bash
sites-deploy --self-update
```

## Использование

```bash
cd /opt/docker-hosting/sites/your-project
sites-deploy
```

## Конфигурация: `.deploy.env`

Файл в корне проекта. Все переменные опциональные. Пример полного набора:

```bash
DOMAIN=poker-show.ru
HEALTH_CHECKS="local:http://127.0.0.1:3002/health public:https://${DOMAIN}/health"
HEALTH_RETRIES=20
HEALTH_DELAY=1
REQUIRE_FILES="api/.env"
DIRTY_EXCLUDE=""
BRANCH=main
BUILD_SERVICES=""       # пусто = все, иначе "service-a service-b"
UP_SERVICES=""          # пусто = все
SKIP_BUILD=0            # 1 чтобы пропустить docker compose build
PRE_BUILD_COMMAND=""    # команда перед docker compose build, например "npm run build"
GIT_TIMEOUT=60          # таймаут git fetch/pull в секундах
```

### Что значит каждое

| Переменная | Назначение |
|---|---|
| `DOMAIN` | Используется в выводе и (по умолчанию) `PUBLIC_HEALTH_URL`. |
| `HEALTH_CHECKS` | Пробелов-separated пары `label:url`. Пусто → шаг пропускается. |
| `HEALTH_RETRIES` | Сколько раз пытаться до фейла. |
| `HEALTH_DELAY` | Секунд между попытками. |
| `REQUIRE_FILES` | Список файлов, обязательных для деплоя (типа `api/.env`). |
| `DIRTY_EXCLUDE` | Файлы которые можно иметь в worktree (`deploy` и `.deploy.env` уже исключены). |
| `BRANCH` | Имя ветки origin для fetch/pull. |
| `BUILD_SERVICES` | Если нужно собирать только часть сервисов. |
| `UP_SERVICES` | Если нужно поднимать только часть сервисов. |
| `SKIP_BUILD` | Не запускать `docker compose build`. |
| `PRE_BUILD_COMMAND` | Команда из корня проекта после `git pull`, до `.deploy/pre-build.sh` и `docker compose build`. Удобно для проектов, где Dockerfile копирует уже готовую сборку, например `npm run build` для Next.js standalone. |
| `GIT_TIMEOUT` | Таймаут для `git fetch` и `git pull`; git prompt отключён, чтобы auth/network проблемы не зависали молча. |

## Хуки: `.deploy/*.sh`

Если файл существует — будет запущен на нужном шаге.

Если для простого случая не нужен отдельный shell-файл, используйте `PRE_BUILD_COMMAND` в `.deploy.env`:

```bash
PRE_BUILD_COMMAND="npm run build"
```

| Файл | Когда |
|---|---|
| `.deploy/pre-build.sh` | После git pull, до `docker compose build` |
| `.deploy/pre-up.sh` | После build, до `docker compose up -d` |
| `.deploy/post-up.sh` | После того как контейнеры подняты, до health-чеков |

Каждый хук получает env-переменные:

- `$BRANCH` — текущая ветка
- `$BEFORE_REF` — короткий хэш до pull
- `$AFTER_REF` — короткий хэш после pull
- `$PROJECT_DIR` — абсолютный путь корня проекта
- `$PROJECT_NAME` — имя папки проекта

Хук может проверять было ли что-то изменено, например миграции:

```bash
# .deploy/pre-up.sh
#!/usr/bin/env bash
set -euo pipefail
if git diff --name-only "$BEFORE_REF..$AFTER_REF" | grep -q '^app/data/migrations/'; then
  docker compose up -d postgres
  docker compose run --rm app npm run migrate-db
fi
```

## Последовательность шагов

```
[1/9] Checking dependencies      (git, docker, curl)
[2/9] Fetching latest changes    (git fetch origin BRANCH)
[3/9] Verifying clean worktree   (git status --porcelain)
[4/9] Pulling (fast-forward only)
[5/9] Validating configuration   (REQUIRE_FILES + docker compose config)
[6/9] Building images            ← .deploy/pre-build.sh ← docker compose build
[7/9] Starting containers        ← .deploy/pre-up.sh ← docker compose up -d --force-recreate ← .deploy/post-up.sh
[8/9] Health checks              (HEALTH_CHECKS)
[9/9] Done
```

## Примеры

См. `examples/poker-show/` (статика + Python API + Telegram-уведомления)
и `examples/megamozgo/` (Next.js + Postgres + миграции + Telegram).
