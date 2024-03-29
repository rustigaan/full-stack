#!/bin/bash

set -e

SED_EXT=-r
case $(uname) in
Darwin*)
        SED_EXT=-E
esac
export SED_EXT

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"
COMPOSE="${PROJECT}/docker"
export DOCKER_REPOSITORY='dendrite2go'

: "${SILENT:=true}"
source "${BIN}/lib-verbose.sh"

: "${ENSEMBLE_NAME:=example}"
: "${EXTRA_VOLUMES:=}"
: "${EXTRA_NETWORKS:=}"
source "${PROJECT}/etc/settings-local.sh"

if [[ ".$1" = '.--dev' ]]
then
  EXTRA_NETWORKS="${EXTRA_NETWORKS}
  nix-dev:
    external: true"
  EXTRA_NETWORKS_FOR_PROXY="${EXTRA_NETWORKS_FOR_PROXY}
      - nix-dev"
fi

export VOLUMES=''
if [[ -n "${EXTRA_VOLUMES}" ]]
then
    VOLUMES="
    volumes:${EXTRA_VOLUMES}"
fi

BASE="${COMPOSE}/docker-compose"
TEMPLATE="${BASE}-template.yml"
TARGET="${BASE}.yml"
VARIABLES="$(tr '$\012' '\012$' < "${TEMPLATE}" | sed -e '/^[{][A-Za-z_][A-Za-z0-9_]*[}]/!d' -e 's/^[{]//' -e 's/[}].*//')"

function re-protect() {
    # shellcheck disable=SC2016
    sed "${SED_EXT}" -e 's/([[]|[]]|[|*?^$()/])/\\\1/g' -e 's/$/\\/g' -e '$s/\\$//'
}

function substitute() {
    local VARIABLE="$1"
    local VALUE
    VALUE="$(eval "echo \"\${${VARIABLE}}\"" | re-protect)"
    log "VALUE=[${VALUE}]"
    if [[ -n "$(eval "echo \"\${${VARIABLE}+true}\"")" ]]
    then
        sed "${SED_EXT}" -e "s/[\$][{]${VARIABLE}[}]/${VALUE}/g" "${TARGET}" > "${TARGET}~"
        mv "${TARGET}~" "${TARGET}"
    fi
}

cp "${TEMPLATE}" "${TARGET}"
for VARIABLE in ${VARIABLES}
do
    log "VARIABLE=[${VARIABLE}]"
    substitute "${VARIABLE}"
done
"${SILENT}" || diff -u "${TEMPLATE}" "${TARGET}" || true

(
    cd "${COMPOSE}"
    docker-compose -p "${ENSEMBLE_NAME}" up
)