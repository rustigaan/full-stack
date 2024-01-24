#!/bin/bash

if [[ ! -f '/nix/.initialized' ]] && [[ -f '/root/nix-store.tar.gz' ]]
then
  tar -C / -xzf '/root/nix-store.tar.gz'
fi

mkdir -p /nix/var/nix/profiles/per-user/somebody
chown somebody:somebody /nix/var/nix/profiles/per-user/somebody

eval "$(tail -1 /etc/init/nix-daemon.conf)"
