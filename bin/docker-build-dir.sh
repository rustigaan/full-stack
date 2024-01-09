#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"

source "${BIN}/lib-verbose.sh"
source "${BIN}/lib-local-settings.sh"

DIRECTORY="$1" ; shift
if [[ -z "${DIRECTORY}" ]]
then
  DIRECTORY='.'
fi

(
  cd "${DIRECTORY}" || exit 1
  IMAGE_NAME="$(basename "$(pwd)")"
  docker build -t "${DOCKER_REPOSITORY}/${IMAGE_NAME}:latest" "$@" .
)
