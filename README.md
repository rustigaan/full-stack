# Rust full-stack PoC

A proof of concept of a full stack Rust project built on the same principles as [archetype-rust-axon](https://github.com/rustigaan/archetype-rust-axon).

An archetypal Rust project that uses AxonServer for Event Sourcing and CQRS.
This project uses the [dendrite crate](https://crates.io/crates/dendrite) ([rustic-dendrite git repo](https://github.com/dendrite2go/rustic-dendrite)) to connect to [AxonServer](https://axoniq.io/product-overview/axon-server).

This is a fork of the original archetype-rust-axon project with the intention to replace the React frontend with a frontend based on the Rusty [Yew-framework](https://crates.io/crates/yew) that can be compiled to Web-assembly.

# Nix

I got sidetracked and started to add building and packaging with Nix before I started on the Yew frontend. I followed the series of blog posts [Building a Rust service with Nix](https://fasterthanli.me/series/building-a-rust-service-with-nix) pretty closely.

# Stack

In alphabetic order:

* [Bash](https://www.gnu.org/software/bash/manual/bash.html): The shell, or command language interpreter, for the GNU operating system — _for building and deploying_
* [AxonServer](https://axoniq.io/product-overview/axon-server): A zero-configuration message router and event store for Axon ([docker image](https://hub.docker.com/r/axoniq/axonserver/)) — _as the Event Store_
* [Docker compose](https://docs.docker.com/compose/): A tool for defining and running multi-container Docker applications — _for spinning up development and test environments_
* [MongoDB](https://mongodb.com) NoSQL Document store ([docker image](https://hub.docker.com/r/mongodb/mongodb-community-server)) — _for query models (though any tokio-compatible persistence engine will do)_
* [Envoy proxy](https://www.envoyproxy.io/): An open source edge and service proxy, designed for cloud-native applications ([docker image](https://hub.docker.com/u/envoyproxy/)) — _to decouple microservices_
* [Nix](https://nixos.org/): Declarative builds and deployments ([docker image](https://hub.docker.com/r/nixpkgs/nix-flakes/tags)) — _for repeatable builds_
* [React](https://reactjs.org/): A JavaScript library for building user interfaces — _for the front-end_
* [Rust](https://www.rust-lang.org): A language empowering everyone to build reliable and efficient software ([docker image](https://hub.docker.com/_/rust)) — _for the back-end_
* [Tokio](https://github.com/tokio-rs/tokio): A runtime for writing reliable, asynchronous, and slim applications with the Rust programming language — _as a runtime for the backend_
* [Tonic](https://github.com/hyperium/tonic): A Rust implementation of [gRPC](https://grpc.io/) with first class support of async/await — _for the plumbing on the back-end_

# Usage

Use this project as a template for new Event Sourced CQRS projects with AxonServer by clicking the "Use this template" button of GitHub.

The file `etc/settings-sample.sh` contains sample settings for the project. It is advised to change at least the variable `ENSEMBLE_NAME` _before_ running `clobber-build-and-run.sh` when creating a new project from the template. The script `clobber-build-and-run.sh` automatically creates `etc/settings-local.sh` from `etc/settings-sample.sh` if it is not present. The file `etc/settings-local.sh` is ignored by git, so your local settings stay local.

The script `clobber-build-and-run.sh` takes the following arguments (options only work in the given order; when switched around the behavior is undefined):

| option                  | description                                                                                                                                                   |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `-v`                    | once or twice for debug or trace mode respectively                                                                                                            |
| `--help`                | show a brief usage reminder                                                                                                                                   |
| `--tee <file>`          | write the output also to the given file                                                                                                                       |
| `--skip-build`          | skip the build phase, only clobber and run                                                                                                                    |
| `--build-uses-siblings` | expose the parent of the project to the Rust compiler, so that the build can reference sibling projects (_e.g._, for testing changes to the dendrite library) |
| `--back-end-only`       | build only the back-end, not the front-end<br/>(most useful with `--dev`)                                                                                     |
| `--no-clobber`          | skip removal of the docker volumes where the data is kept                                                                                                     |
| `--dev`                 | use the development version of the front-end<br/>React will automatically recompile changes to front-end code                                                 |

The file `etc/docker-compose.yml` is recreated from `etc/docker-compose-template.yml` by script `docker-compose-up.sh` for each run of `clobber-build-and-run.sh`.

The `--dev` mode deploys a `node.js` container that serves the sources directly from the `present` directory. React will dynamically recompile and reload sources when they are changed. Otherwise, an `nginx` container is deployed that serves the 'production' generated front-end.

There is a separate script `bin/docker-compose-up.sh` that only regenerates the `docker-compose.yml` and invokes docker compose up. It only takes options `-v1 (once or twice)` and `--dev`.

There is also a basic script `grpcurl-call.sh` that provides access to the gRPC API of the back-end from the command-line.