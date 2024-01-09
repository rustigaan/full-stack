FROM nixpkgs/nix-flakes

SHELL [ "/bin/bash", "-c" ]

RUN mkdir -p /root/.config/nix
COPY nix.conf /root/.config/nix/nix.conf
COPY dot_bashrc.sh /root/.bashrc
COPY run-daemon.sh /root/.
ENV HOME=/root
RUN nix profile install \
    'nixpkgs#gnugrep' \
    'nixpkgs#gnused' \
    'nixpkgs#shadow'

RUN set -e ; \
    chmod u+x,go= /root/run-daemon.sh ; \
    /root/.nix-profile/bin/useradd -u 1000 -U -m somebody ; \
    mkdir -p /home/somebody/.config/nix /home/somebody/.ssh /nix/var/nix/profiles/per-user/somebody
COPY nix.conf /home/somebody/.config/nix/nix.conf
COPY dot_bashrc.sh /home/somebody/.bashrc
RUN set -ex ; \
    chown -R somebody:somebody /home/somebody /nix/var/nix/profiles/per-user/somebody ; \
    chmod go= /home/somebody/.ssh

USER root
WORKDIR /root
