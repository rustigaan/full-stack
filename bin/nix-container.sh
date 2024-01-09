#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/lib-verbose.sh"

REBUILD='false'
DOCKER_BUILD_FLAGS=()
if [[ ".$1" = '.--rebuild' ]]
then
  REBUILD='true'
  DOCKER_BUILD_FLAGS+=('--no-cache')
fi

if "${REBUILD}" || [[ -z "$(docker image ls --format json 'rustigaan/nix:latest')" ]]
then
  docker build "${DOCKER_BUILD_FLAGS[@]}" -t 'rustigaan/nix:latest' -f "${PROJECT}/docker/nix/Dockerfile" "${PROJECT}/docker/nix"
fi

COMMAND=('bash')
if [[ ".$1" = '.--no-bash' ]]
then
  shift
  COMMAND=()
fi

docker volume create --driver local nix

SSH_DIR="${HOME}/.ssh"

## LOCAL="${PROJECT}/data/local"
LOCAL="${PROJECT}"

CONTAINER_WORK_DIR="${PWD}"
log "CONTAINER_WORK_DIR#LOCAL=[${CONTAINER_WORK_DIR#${LOCAL}}]"
log "LOCAL#CONTAINER_WORK_DIR=[${LOCAL#${CONTAINER_WORK_DIR}}]"
if [[ ".${CONTAINER_WORK_DIR#${LOCAL}}" = ".${CONTAINER_WORK_DIR}" ]] && [[ ".${LOCAL#${CONTAINER_WORK_DIR}}" = ".${LOCAL}" ]]
then
  CONTAINER_WORK_DIR="${LOCAL}"
fi
log "CONTAINER_WORK_DIR=[${CONTAINER_WORK_DIR}]"

docker container rm nix-daemon >/dev/null 2>&1 || true

docker run --rm -ti \
    --mount "type=volume,source=nix,target=/nix" \
    --mount "type=bind,source=${SSH_DIR},target=/home/somebody/.ssh" \
    --mount "type=bind,source=${LOCAL},target=${LOCAL}" \
    -w "${CONTAINER_WORK_DIR}" \
    --name 'nix-daemon' \
    'rustigaan/nix:latest' \
    "${COMMAND[@]}" "$@"
