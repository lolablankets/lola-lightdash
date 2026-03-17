compose := "docker compose -f docker/docker-compose.dev.mini.yml"
dbt_project := env("LOLA_DBT_PROJECT", env("HOME", "") / "Developer/lola/packages/transform/transform")

_env := 'set -a; source "' + justfile_directory() + '/.env.development.local"; set +a; export PATH="' + justfile_directory() + '/.venvs/bin:$PATH"; export DBT_DEMO_DIR="' + justfile_directory() + '/examples/full-jaffle-shop-demo"; eval "$(fnm env)"; fnm use 20 > /dev/null'

# List available recipes
default:
    @just --list

# Start everything: infra + dev servers
up: infra-up
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    exec pnpm dev

# Start only infra (Postgres, MinIO, headless browser, mailpit, NATS)
infra-up:
    {{ compose }} up -d

# Stop infra containers
infra-down:
    {{ compose }} down

# Reset database: drop, migrate, seed
reset-db:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    docker exec docker-db-dev-1 psql -U postgres -c 'drop schema public cascade; create schema public;'
    pnpm -F backend migrate
    pnpm -F backend seed

# Run migrations only
migrate:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    pnpm -F backend migrate

# Rollback last migration
rollback:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    pnpm -F backend rollback-last

# Create a new migration
create-migration name:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    pnpm -F backend create-migration {{ name }}

# Run tests for a package (common, backend, frontend)
test package="common":
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    if [ "{{ package }}" = "backend" ]; then
        pnpm -F backend test:dev:nowatch
    else
        pnpm -F {{ package }} test
    fi

# Lint a package
lint package="common":
    pnpm -F {{ package }} lint

# Typecheck a package
typecheck package="common":
    pnpm -F {{ package }} typecheck

# Regenerate OpenAPI specs from TSOA controllers
generate-api:
    pnpm generate-api

# Run a psql command against the dev database (e.g. just psql "SELECT 1")
psql query:
    docker exec docker-db-dev-1 psql -U postgres -c "{{ query }}"

# Show infra container status
status:
    @{{ compose }} ps

# Tail infra logs
logs *args:
    {{ compose }} logs -f {{ args }}

# Create a Lola Analytics Dev project with Snowflake credentials
setup-project:
    ./scripts/setup-lola-project.sh

# Log the Lightdash CLI into the local instance using the seed PAT
login:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    lightdash login http://localhost:8080 --token ldpat_deadbeefdeadbeefdeadbeefdeadbeef

# Deploy the Lola dbt project into the local Lightdash instance
deploy target='dev-sf':
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    echo "Deploying dbt project from {{ dbt_project }} (target: {{ target }})"
    cd "{{ dbt_project }}"
    lightdash deploy --target {{ target }} --verbose

# Full setup from scratch: install deps, start infra, reset db, start dev
bootstrap: infra-up
    #!/usr/bin/env bash
    set -euo pipefail
    {{ _env }}
    pnpm install
    just reset-db
    exec pnpm dev
