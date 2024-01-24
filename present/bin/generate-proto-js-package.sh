#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
MODULE="$(dirname "${BIN}")"
PROJECT="$(dirname "${MODULE}")"

source "${PROJECT}/bin/lib-verbose.sh"

cd "${PROJECT}/proto"

if [[ ! -f 'proto_example.proto' ]]
then
  error "Protocol buffer specification files for back-end API not found in: $(pwd)"
fi

log "Generating JS stubs from $(pwd)"

OUT_DIR="${MODULE}/src/grpc/backend"
mkdir -p "${OUT_DIR}"

protoc --js_out="import_style=commonjs:${OUT_DIR}" --grpc-web_out="import_style=commonjs+dts,mode=grpcwebtext:${OUT_DIR}" -I. *.proto
(
  # Add /* eslint-disable */
  cd "${OUT_DIR}"
  log "ID: [$(id)]"
  log "CWD: $(ls -ld "$(pwd)")"
  log "TMP=[${TMP}]"
  JS_FILES=(*.js)
  if [[ ${#FILES[@]} -gt 1 ]] || [[ ".${FILES[0]}" != '.*.js' ]]
  then
    for JS in "${JS_FILES[@]}"
    do
      sed -E \
        -e '1s:^/\* eslint-disable \*/$:/*@@@ eslint-disable @@@*/:' \
        -e "1i\\
/* eslint-disable */" \
        -e '/^\/\*@@@ eslint-disable @@@\*\//d' \
        "./${JS}" \
        > "./${JS}~"
      if [[ -s "./${JS}~" ]]
      then
        mv "./${JS}~" "./${JS}"
      fi
    done
  else
    log "No JavaScript files found"
  fi
)
