#!/bin/bash

mkdir -p /nix/var/nix/profiles/per-user/somebody
chown somebody:somebody /nix/var/nix/profiles/per-user/somebody

eval "$(tail -1 /etc/init/nix-daemon.conf)"
