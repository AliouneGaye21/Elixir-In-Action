#!/bin/sh
# wait-for-postgres.sh (versione finale e semplificata)

set -e

# Cicla finché il comando `psql` non riesce a connettersi con successo.
# Le variabili d'ambiente sono fornite da docker-compose.
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up!"
