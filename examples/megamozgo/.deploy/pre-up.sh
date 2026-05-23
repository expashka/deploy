#!/usr/bin/env bash
# Run migrations if migration files changed (or if RUN_MIGRATIONS=1 is forced).
set -euo pipefail

NEED_MIGRATIONS=0
if git diff --name-only "$BEFORE_REF..$AFTER_REF" 2>/dev/null \
    | grep -Eq '^app/data/(migrations/.*\.sql|schema\.sql)$'; then
  NEED_MIGRATIONS=1
fi
if [[ "${RUN_MIGRATIONS:-}" == "1" ]]; then
  NEED_MIGRATIONS=1
fi

if [[ "$NEED_MIGRATIONS" == "1" ]]; then
  echo "→ migrations needed"
  docker compose up -d postgres
  docker compose run --rm app npm run migrate-db
else
  echo "no migration files changed"
fi
