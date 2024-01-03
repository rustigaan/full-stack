#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/lib-verbose.sh"
source "${BIN}/lib-sed.sh"

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

if [[ -z "${SIGN_PRIVATE_KEY}" ]]
then
  SIGN_PRIVATE_KEY="${ROOT_PRIVATE_KEY}"
fi

(
  cd "${PROJECT}" || exit 1
  log "DIR=[$(pwd)]"

  (
    echo ">>> Secrets"
    cat "${PROJECT}/etc/secrets-local.yaml" \
      | docker run --rm -i karlkfi/yq -r '.users | to_entries[] | .key + " " + .value.secret' \
      | while read USER_ID PASSWORD_ENCRYPTED
        do
          log ">>> ${USER_ID}: ${PASSWORD_ENCRYPTED}"
          echo "${USER_ID}=${PASSWORD_ENCRYPTED}"
        done

    if [[ -f ""${PROJECT}/etc/application-local.yaml"" ]]
    then
      echo ">>> Properties"
      cat "${PROJECT}/etc/application-local.yaml" \
        | docker run --rm -i karlkfi/yq -r --stream \
            '. | select(length > 1) | .[0][0] + (reduce .[0][1:][] as $item ("" ; . + "." + ($item | tostring))) + "=" + .[1]'
    fi
  ) > "${PROJECT}/target/config.data"
)