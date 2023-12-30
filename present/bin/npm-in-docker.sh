#!/usr/bin/env bash

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

docker run -i -v "${PROJECT}:${PROJECT}" -w "${PROJECT}" -e 'NODE_OPTIONS=--openssl-legacy-provider' node:21-alpine npm "$@"
