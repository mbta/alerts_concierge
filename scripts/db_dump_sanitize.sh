#!/usr/bin/env bash

# Run like PGHOST=ACTUAL_HOST PGPASSWORD=ACTUAL_PASSWORD BUCKET==ACTUAL_BUCKET ./scripts/db_dump_sanitize.sh

timestamp=$(TZ=UTC date +%Y-%m-%dT%H_%M_%SZ)

# Skipping the table:
# - guardian_tokens
# - metadata
# - versions
pg_dump \
--port=5432 \
--username=alerts_concierge \
--dbname=alerts_concierge_prod \
--table=alerts \
--table=informed_entities \
--table=notification_subscriptions \
--table=notifications \
--table=schema_migrations \
--table=subscriptions \
--table=trips \
--table=users \
--no-owner \
--data-only \
| elixir ./scripts/sanitize_db_dump.exs \
| gzip \
| aws s3 cp - s3://${BUCKET}/alerts-concierge/prod-db-scrubbed-${timestamp}.sql.gz
