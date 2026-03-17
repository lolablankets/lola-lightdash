#!/usr/bin/env bash
# Create a Lola Analytics Dev project in the local Lightdash instance
# using the same Snowflake credentials as the Hetzner remote.
set -euo pipefail

API_URL="${SITE_URL:-http://localhost:8080}"
PAT="ldpat_deadbeefdeadbeefdeadbeefdeadbeef"

SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT:-BEB06402.us-west-2}"
SNOWFLAKE_USERNAME="${SNOWFLAKE_USERNAME:-ETL_SERVICE_ACCOUNT}"
SNOWFLAKE_ROLE="${SNOWFLAKE_ROLE:-TRANSFORMER_ROLE}"
SNOWFLAKE_WAREHOUSE="${SNOWFLAKE_WAREHOUSE:-ETL_WH}"
SNOWFLAKE_DATABASE="${SNOWFLAKE_DATABASE:-LOLA_ANALYTICS_DEV}"
SNOWFLAKE_SCHEMA="${SNOWFLAKE_SCHEMA:-z04_marts_utilities}"
SNOWFLAKE_PRIVATE_KEY_PATH="${SNOWFLAKE_PRIVATE_KEY_PATH:-$HOME/.snowflake/rsa_key.p8}"

if [[ ! -f "$SNOWFLAKE_PRIVATE_KEY_PATH" ]]; then
    echo "Error: Snowflake private key not found at $SNOWFLAKE_PRIVATE_KEY_PATH" >&2
    exit 1
fi

PRIVATE_KEY=$(cat "$SNOWFLAKE_PRIVATE_KEY_PATH")
PRIVATE_KEY_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$PRIVATE_KEY")

echo "Creating Lola Analytics Dev project at $API_URL..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: ApiKey $PAT" \
    -H "Content-Type: application/json" \
    "$API_URL/api/v1/org/projects" \
    -d @- <<EOF
{
    "name": "Lola Analytics Dev",
    "type": "DEFAULT",
    "dbtConnection": {
        "type": "none",
        "target": "dev-sf"
    },
    "warehouseConnection": {
        "type": "snowflake",
        "account": "$SNOWFLAKE_ACCOUNT",
        "user": "$SNOWFLAKE_USERNAME",
        "role": "$SNOWFLAKE_ROLE",
        "warehouse": "$SNOWFLAKE_WAREHOUSE",
        "database": "$SNOWFLAKE_DATABASE",
        "schema": "$SNOWFLAKE_SCHEMA",
        "privateKey": $PRIVATE_KEY_JSON,
        "authenticationType": "private_key",
        "clientSessionKeepAlive": true,
        "queryTag": "etl_dbt"
    },
    "dbtVersion": "v1.11"
}
EOF
)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    PROJECT_UUID=$(echo "$BODY" | python3 -c "import json,sys; r=json.loads(sys.stdin.read())['results']; print(r.get('projectUuid') or r['project']['projectUuid'])")
    echo "Project created: $PROJECT_UUID"
    echo "Open $API_URL/projects/$PROJECT_UUID/home"
else
    echo "Error ($HTTP_CODE): $BODY" >&2
    exit 1
fi
