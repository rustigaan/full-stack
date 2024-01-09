#!/bin/bash

nix profile install \
    'nixpkgs#direnv' \
    'nixpkgs#findutils' \
    'nixpkgs#git-crypt' \
    'nixpkgs#gnugrep' \
    'nixpkgs#gnused' \
    'nixpkgs#vim' \
    'nixpkgs#which'
