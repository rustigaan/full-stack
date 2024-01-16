#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"

source "${BIN}/lib-verbose.sh"

# shellcheck disable=SC2046
docker volume ls --filter driver=local --format '{{.Name}}' \
  | grep -E '^[0-9a-f]{64}$' \
  | tr '\012' '\000' \
  | xargs -0 docker volume rm \
  || true

docker image ls -a --filter dangling=true --format '{{.ID}}|{{.Repository}}' \
  | sed -n -e 's/|<none>$//p' \
  | tr '\012' '\000' \
  | xargs -0 echo docker image rm \
  || true
