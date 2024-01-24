#!/usr/bin/env bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
MODULE="$(dirname "${BIN}")"
PROJECT="$(dirname "${MODULE}")"

source "${PROJECT}/bin/lib-verbose.sh"
source "${PROJECT}/etc/settings-local.sh"

DOCKER_CMD=(docker run --rm -v "${PROJECT}:${PROJECT}" -w "${BIN}" --user "$(id -u):$(id -g)" "dendrite2go/build-protoc" ./generate-proto-js-package.sh "${FLAGS_INHERIT[@]}")
log "Run with protoc in docker container: [${DOCKER_CMD[*]}]"
"${DOCKER_CMD[@]}"

DOCKER_CMD=(docker run --rm -i -v "${MODULE}:${MODULE}" -w "${MODULE}" -e 'NODE_OPTIONS=--openssl-legacy-provider' node:21-alpine npm run build)
log "Build in docker container: [${DOCKER_CMD[*]}]"
"${DOCKER_CMD[@]}"
