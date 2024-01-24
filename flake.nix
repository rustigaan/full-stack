{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          # cf. https://crane.dev/source-filtering.html
          protoFilter = path: _type: builtins.match ".*proto$" path != null;
          protoOrCargo = path: type:
            (protoFilter path type) || (craneLib.filterCargoSources path type);
          src = pkgs.lib.cleanSourceWith {
            src = craneLib.path ./.; # The original, unfiltered source
            filter = protoOrCargo;
          };

          nativeBuildInputs = with pkgs; [ rustToolchain pkg-config ];
          buildInputs = with pkgs; [ protobuf3_20 protoc-gen-rust ];
          commonArgs = {
            inherit src buildInputs nativeBuildInputs;
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          bin = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
          });
          dockerImage = pkgs.dockerTools.buildImage {
            name = "example_command_api";
            tag = "latest";
            copyToRoot = [ bin ];
            config = {
              Cmd = [ "${bin}/bin/dendrite_example" ];
            };
          };
        in
        with pkgs;
        {
          packages =
            {
              inherit bin dockerImage;
              default = bin;
            };
          devShells.default = mkShell {
            inputsFrom = [ bin ];
          };
        }
      );
}