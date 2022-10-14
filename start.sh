#!/bin/bash

BASE=$PWD
export $(grep -v '^#' .env | xargs)

export FAROS_EMAIL=none@none.com

PGPASSWORD=$HOLOCRON_DB_PASSWORD createdb -h 127.0.0.1 -U $HOLOCRON_DB_USER -p 5432 faros

docker run --rm -v /Users/bryan/_git/faros-community-edition/canonical-schema:/flyway/sql \
flyway/flyway -url=jdbc:postgresql://host.docker.internal:5432/faros -user=$HOLOCRON_DB_USER -password=$HOLOCRON_DB_PASSWORD migrate

cd $BASE/init && npm run build && cd $BASE/init/scripts
METABASE_URL=http://localhost:3000 \
METABASE_USER=admin \
METABASE_PASSWORD=admin \
METABASE_FAROS_DB_HOST=host.docker.internal \
METABASE_USE_SSL=true \
FAROS_DB_PORT=5432 \
FAROS_DB_NAME=faros \
FAROS_DB_USER=$HOLOCRON_DB_USER \
FAROS_DB_PASSWORD=$HOLOCRON_DB_PASSWORD \
./metabase-init.sh

cd init &&
node lib/hasura/init --hasura-url http://127.0.0.1:8080 \
  --admin-secret $HASURA_GRAPHQL_ADMIN_SECRET \
  --database-url postgresql://$HOLOCRON_DB_USER:$HOLOCRON_DB_PASSWORD@host.docker.internal/faros

cd $BASE

# Ensure we're using the latest faros-init image
export FAROS_INIT_IMAGE=farosai.docker.scarf.sh/farosai/faros-ce-init:latest

docker-compose pull faros-init

if [[ $(uname -m 2>/dev/null) == 'arm64' ]]; then
    # Use Metabase images built for Apple M1
    METABASE_IMAGE="farosai.docker.scarf.sh/farosai/metabase-m1" \
        docker-compose up --build --remove-orphans &
else
    docker-compose up --build --remove-orphans &
fi
