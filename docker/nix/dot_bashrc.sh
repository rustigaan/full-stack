PROFILE_BIN="/root/.nix-profile/bin"

function show_project() {
  echo -n "${PROJECT_NAME}"
  if [[ -n "${IN_NIX_SHELL}" ]]
  then
    echo "*"
  fi
}

if [[ "$(id -u)" -eq 0 ]]
then
  PS1='\h:($(show_project))\W # '
else
  PS1='\u@\h:($(show_project))\W $ '
fi

function path_prepend(){
  local NEW_DIR="$1"
  local EXISTING_DIR
  EXISTING_DIR="$(echo "$PATH" | tr ':' '\012' | "${PROFILE_BIN}/sed" -e 's/^/:/' -e 's/$/:/'| "${PROFILE_BIN}/grep" -F ":${NEW_DIR}:")"
  if [[ -z "${EXISTING_DIR}" ]]
  then
    PATH="${NEW_DIR}:${PATH}"
  fi
}

path_prepend "${HOME}/.nix-profile/bin"

## set -x
PER_USER='/nix/var/nix/profiles/per-user'
MY_PROFILE_DIR="${PER_USER}/$(id -un)"
if [[ -L "${HOME}/.nix-profile" ]] && [[ ".$(readlink "${HOME}/.nix-profile")" != ".${MY_PROFILE_DIR}/profile" ]]
then
  rm "${HOME}/.nix-profile"
fi
if [[ ! -L "${HOME}/.nix-profile" ]] && [[ -L "${MY_PROFILE_DIR}/profile" ]]
then
  ln -s "${MY_PROFILE_DIR}/profile" "${HOME}/.nix-profile"
fi
if type direnv >/dev/null 2>&1
then
  :
else
  nix profile install nixpkgs#direnv
  if [[ -d "${MY_PROFILE_DIR}" ]] && [[ ! -L "${MY_PROFILE_DIR}/profile" ]]
  then
    HOME_PROFILES="$(dirname "$(readlink "${HOME}/.nix-profile")")"
    mv "${HOME_PROFILES}"/* "${MY_PROFILE_DIR}"
  fi
  if [[ -L "${HOME}/.nix-profile" ]] && [[ ".$(readlink "${HOME}/.nix-profile")" != ".${MY_PROFILE_DIR}/profile" ]]
  then
    rm "${HOME}/.nix-profile"
  fi
  if [[ ! -L "${HOME}/.nix-profile" ]]
  then
    ln -s "${MY_PROFILE_DIR}/profile" "${HOME}/.nix-profile"
  fi
fi
## set +x

eval "$(direnv hook bash)"