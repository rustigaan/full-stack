#!/usr/bin/env bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

declare -a FLAGS_INHERIT
source "${BIN}/lib-verbose.sh"

if [[ ".$1" = '.--help' ]]
then
    echo "Usage: $(basename "$0") [ -v [ -v ] ] [ --tee <file> | --tee-time ] [ --skip-build ] [ --front-end-only | --back-end-only ] [ --no-clobber ]" >&2
    echo "       $(basename "$0") --help" >&2
    exit 0
fi

if [[ ".$1" = '.--tee' ]]
then
    exec > >(tee "$2") 2>&1
    shift 2
elif [[ ".$1" = '.--tee-time' ]]
then
    TIMESTAMP="$(date '+%Y%m%dT%H%M')"
    LOG_FILE="${PROJECT}/data/local/build-and-run-${TIMESTAMP}.log"
    info "LOG_FILE=[${LOG_FILE}]"
    exec > >(tee "${LOG_FILE}") 2>&1
    shift
fi

DO_BUILD='true'
if [[ ".$1" = '.--skip-build' ]]
then
  DO_BUILD='false'
  shift
fi

DO_BUILD_BACK_END='true'
DO_BUILD_PRESENT='true'
DO_BUILD_SWAGGER_IMAGE='false'
if [[ ".$1" = '.--front-end-only' ]]
then
  DO_BUILD_BACK_END='false'
  shift
elif [[ ".$1" = '.--back-end-only' ]]
then
  DO_BUILD_PRESENT='false'
  shift
fi

DO_CLOBBER='true'
if [[ ".$1" = '.--no-clobber' ]]
then
  DO_CLOBBER='false'
  shift
fi

: "${AXON_SERVER_PORT=8024}"
: "${API_SERVER_PORT=8181}"
: "${ENSEMBLE_NAME=rustic}"
"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

function waitForServerReady() {
    local URL="$1"
    local N="$2"
    if [[ -z "${N}" ]]
    then
        N=120
    fi
    while [[ "${N}" -gt 0 ]]
    do
        N=$(( N - 1 ))
        sleep 1
        if curl -sS "${URL}" >/dev/null 2>&1
        then
            break
        fi
    done
}

function countRunningContainers() {
    local HASH
    for HASH in $(docker-compose -p "${ENSEMBLE_NAME}" ps -q 2>/dev/null)
    do
        docker inspect -f '{{.State.Status}}' "${HASH}"
    done | grep -c running
}

function waitForDockerComposeReady() {
    (
        cd "${COMPOSE}"
        while [[ "$(countRunningContainers)" -gt 0 ]]
        do
            sleep 0.5
        done
    )
}

function start-nix-container() {
  (
    set +e
    "${BIN}/nix-container.sh" --no-stop
    if [[ "$?" -ge 32 ]]
    then
      echo 'true'
    else
      echo 'false'
    fi
  )
}

(
    cd "${PROJECT}"

#    src/bin/generate-root-key-pair.sh
#    src/bin/generate-module-for-trusted-keys.sh

    if "${DO_BUILD}"
    then
        if "${DO_BUILD_BACK_END}"
        then
            # Generate module "trusted_generated".
            ## "${BIN}/generate-module-for-trusted-keys.sh" -v --module-dir 'example_event' 'monolith'
            ## "${BIN}/generate-module-for-trusted-keys.sh" -v 'upload'

            # Build server executables from Rust sources
            info "Build executables for the back-end"
            KEEP_RUNNING="$(start-nix-container)"
            nix-exec.sh -c 'nix build .#dockerImage'
            # shellcheck disable=SC2016
            nix-exec.sh -c 'cat "$(readlink -m result)"' | docker load
            "${KEEP_RUNNING}" || "${BIN}/nix-container.sh" --stop
        fi

        if "${DO_BUILD_PRESENT}"
        then
            info "Build docker images for presentation layer"
            info "TODO"
        fi

        info "Build docker image for proxy"
        docker build -t "${DOCKER_REPOSITORY}/${ENSEMBLE_NAME}-proxy:${ENSEMBLE_IMAGE_VERSION}" docker/proxy

        if "${DO_BUILD_SWAGGER_IMAGE}"
        then
            info "Build docker image for Swagger UI"
            docker build -t "${DOCKER_REPOSITORY}/grpc-swagger" "docker/swagger"
        fi
    fi

    (
        info "Remove pre-existing docker containers for ${ENSEMBLE_NAME}"
        read -ra PRE_EXISTING < <(docker ps --filter "label=com.docker.compose.project=${ENSEMBLE_NAME}" -a --format '{{.ID}}' | tr '\012' ' ' ; echo)
        if [[ "${#PRE_EXISTING[@]}" -gt 0 ]]
        then
            docker rm -f "${PRE_EXISTING[@]}"
        fi
    )

    if "${DO_CLOBBER}"
    then
      info "Remove pre-existing data volumes"
      docker volume rm -f "${ENSEMBLE_NAME}_axon-data"
      docker volume rm -f "${ENSEMBLE_NAME}_axon-eventdata"
      docker volume rm -f "${ENSEMBLE_NAME}_mongodb-data"
    fi
)

info "Prepare configuration data"
"${BIN}/config-prepare.sh"

info "Start containers"
exec "${PROJECT}/bin/docker-compose-up.sh" "${FLAGS_INHERIT[@]}" "$@"