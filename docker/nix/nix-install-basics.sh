#!/bin/bash

nix profile install \
    'nixpkgs#direnv' \
    'nixpkgs#file' \
    'nixpkgs#findutils' \
    'nixpkgs#gawk' \
    'nixpkgs#git-crypt' \
    'nixpkgs#glibc' \
    'nixpkgs#gnugrep' \
    'nixpkgs#gnused' \
    'nixpkgs#less' \
    'nixpkgs#vim' \
    'nixpkgs#which'
