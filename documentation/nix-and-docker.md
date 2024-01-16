# Nix and Docker

Nix keeps (versions of) configurations separate by storing them in directories that changes for each little change that is made to the inputs for the build process for creating the package.

Docker keeps (versions of) configurations separate by exposing read-only layered filesystems in containers (isolated process groups)

This project explores the possibilities of using both Nix and Docker.

We would like to use Nix while building our software and package the resulting software in a Docker image for consistent deployment in various test and production environments.

## One container to rule them all

_One container to find them, and in darkness bind them_

The /docker/nix directory of this project specifies an image for a single docker container that is meant to run as a daemon. The daemon is started by script `nix-container.sh`. This script mounts the root of the Git repository that contains the current directory.

Build stages are run on that container using script `nix-exec.sh`. This script can be executed with flag `--root` when necessary.

To build an image, the resulting nix packages and their dependencies first have to be copied out of the `nix` volume to a staging area. Then a separate `docker build` process that starts from a minimal `nixos` base image is used to package the files from the staging area in new container image. The resulting image is the deployable artifact.