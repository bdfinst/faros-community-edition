#!/bin/bash

export FAROS_EMAIL=none@none.com

# Ensure we're using the latest faros-init image
export FAROS_INIT_IMAGE=farosai.docker.scarf.sh/farosai/faros-ce-init:latest

docker-compose pull faros-init

if [[ $(uname -m 2> /dev/null) == 'arm64' ]]; then
    # Use Metabase images built for Apple M1
    METABASE_IMAGE="farosai.docker.scarf.sh/farosai/metabase-m1" \
    docker-compose up --build --remove-orphans &
else
    docker-compose up --build --remove-orphans &
fi

