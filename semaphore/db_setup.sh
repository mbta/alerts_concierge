#!/bin/bash
set -e

sem-service start postgres 10
export DATABASE_URL_TEST="postgresql://$DATABASE_POSTGRESQL_USERNAME:$DATABASE_POSTGRESQL_PASSWORD@localhost:5432/alert_concierge_test"
