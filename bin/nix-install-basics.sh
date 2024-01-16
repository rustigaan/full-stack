#!/bin/bash

nix profile install \
    'nixpkgs#direnv' \
    'nixpkgs#findutils' \
    'nixpkgs#gawk' \
    'nixpkgs#git-crypt' \
    'nixpkgs#gnugrep' \
    'nixpkgs#gnused' \
    'nixpkgs#less' \
    'nixpkgs#vim' \
    'nixpkgs#which'
