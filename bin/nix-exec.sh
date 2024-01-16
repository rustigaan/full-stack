#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"

source "${BIN}/lib-verbose.sh"

DOCKER_FLAGS=()
if [[ -t 0 ]] && [[ -t 1 ]]
then
  DOCKER_FLAGS+=('-t')
fi

USER_FLAGS=(-u somebody:somebody -e HOME=/home/somebody)
if [[ ".$1" = '.--root' ]]
then
  USER_FLAGS=(-e HOME=/root)
  shift
fi

COMMAND=('bash')
if [[ ".$1" = '.--no-bash' ]]
then
  COMMAND=()
  shift
fi

DOCKER_COMMAND=(docker exec "${USER_FLAGS[@]}" "${DOCKER_FLAGS[@]}" -i nix-daemon "${COMMAND[@]}" "$@")
log "DOCKER_COMMAND=${DOCKER_COMMAND[*]}"
"${DOCKER_COMMAND[@]}"
