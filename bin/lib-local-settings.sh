#!/usr/bin/false

SETTINGS_LOCAL="$(dirname "${BIN}")/etc/settings-local.sh"
if [[ ! -f "${SETTINGS_LOCAL}" ]]
then
  "${BIN}/create-local-settings.sh"
fi
# shellcheck disable=SC1090
source "${SETTINGS_LOCAL}"
