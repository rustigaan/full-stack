#!/usr/bin/env bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PRESENT="$(dirname "${BIN}")"
PROJECT="$(dirname "${PRESENT}")"

source "${PROJECT}/bin/verbose.sh"

DOCKER_CMD=(docker run --rm -i -v "${PRESENT}:${PRESENT}" -w "${PRESENT}" -e 'NODE_OPTIONS=--openssl-legacy-provider' node:21-alpine npm install)
log "DOCKER_CMD=[${DOCKER_CMD[*]}]"
"${DOCKER_CMD[@]}"
