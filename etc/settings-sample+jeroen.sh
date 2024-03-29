#!/usr/bin/false

DOCKER_REPOSITORY='rustigaan'
ENSEMBLE_NAME=rustic
ENSEMBLE_IMAGE_VERSION='0.0.1-SNAPSHOT'
RUST_TAG='1.75.0'
UI_SERVER_PORT='3000'
API_SERVER_PORT='8181'
AXON_SERVER_PORT='8024'
AXON_VERSION='4.3.1'
ELASTIC_SEARCH_VERSION='7.6.1'
MONGODB_VERSION='6.0.5-ubi8'
ROOT_PRIVATE_KEY='data/secure/id_rsa'
ADDITIONAL_TRUSTED_KEYS=()
NIX_STORE_VOLUME="${USER}-nix-store"

EXTRA_VOLUMES="# Extra volumes
      -
        type: bind
        source: ${PROJECT}
        target: ${PROJECT}"

INJECT_CONFIG_VOLUMES="# Inject config volumes
      - type: bind
        source: ${HOME}/.ssh
        target: ${HOME}/.ssh"
