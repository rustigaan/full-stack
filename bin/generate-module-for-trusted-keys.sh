#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/verbose.sh"
source "${PROJECT}/etc/settings-local.sh"

MODULE_DIR='event_handlers'
if [[ ".$1" = '.--module-dir' ]]
then
  MODULE_DIR="$2"
  shift 2
fi

COMPONENT="$1" ; shift

SRC="${PROJECT}/${COMPONENT}/src"
MODULE="${SRC}/${MODULE_DIR}/trusted_generated.rs"

mkdir -p "$(dirname "${MODULE}")"

echo '//! Generated module. Do not edit.

use anyhow::Result;
use dendrite::auth::dendrite_config::PublicKey;

pub fn init() -> Result<()> {' > "${MODULE}"
(
  cd "${PROJECT}" || exit 1
  N=0
  for F in "${ROOT_PRIVATE_KEY}.pub" "${ADDITIONAL_TRUSTED_KEYS}"
  do
    if [[ -z "${F}" ]]
    then
      continue
    fi
    log ">>> Trusted key: [${F}]"
    KEY="$(cut -d ' ' -f2 "${F}")"
    NAME="$(cut -d ' ' -f3 "${F}")"
    if [[ -z "${KEY}" ]]
    then
      continue
    fi
    if [[ -z "${NAME}" ]]
    then
      N=$((${N} + 1))
      NAME="key-${N}"
    fi
    echo "    let public_key = PublicKey {"
    echo "        name: \"${NAME}\".to_string(),"
    echo "        public_key: \"${KEY}\".to_string(),"
    echo "    };"
    echo "    dendrite::auth::unchecked_set_public_key(public_key.clone())?;"
    echo "    dendrite::auth::unchecked_set_key_manager(public_key.clone())?;"
  done >> "${MODULE}"
)
echo '    Ok(())
}' >> "${MODULE}"

( "${TRACE}" && sed -e 's/^/+/' "${MODULE}" ) || true
