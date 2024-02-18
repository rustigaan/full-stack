{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-for-wasm-bindgen.url = "github:NixOS/nixpkgs/654114118be7ed053139faafc404a4a6583b0692";
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
  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane, nixpkgs-for-wasm-bindgen, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          inherit (pkgs) lib;

          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            targets = [ "wasm32-unknown-unknown" ];
          };
          craneLib = ((crane.mkLib pkgs).overrideToolchain rustToolchain).overrideScope (_final: _prev: {
            # The version of wasm-bindgen-cli needs to match the version in Cargo.lock. You
            # can unpin this if your nixpkgs commit contains the appropriate wasm-bindgen-cli version
            inherit (import nixpkgs-for-wasm-bindgen { inherit system; }) wasm-bindgen-cli;
          });

          src = lib.cleanSourceWith {
            src = ./.; # The original, unfiltered source
            filter = path: type:
              (lib.hasSuffix "\.proto" path) ||
              (lib.hasSuffix "\.html" path) ||
              (lib.hasSuffix "\.scss" path) ||
              # Example of a folder for images, icons, etc
              (lib.hasInfix "/assets/" path) ||
              # Default filter from crane (allow .rs files)
              (craneLib.filterCargoSources path type)
            ;
          };

          buildInputs = with pkgs; [
            # Add additional build inputs here
            ## protobuf3_20 protoc-gen-rust
          ] ++ lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            libiconv
          ];
          commonArgs = {
            inherit src buildInputs;
            strictDeps = true;
            CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
          };

          cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
            doCheck = false;
          });

          wasm = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
            doCheck = false;
            wasm-bindgen-cli = pkgs.wasm-bindgen-cli.override {
              version = "0.2.91";
              hash = "sha256-f/RK6s12ItqKJWJlA2WtOXtwX4Y0qa8bq/JHlLTAS3c=";
              cargoHash = "sha256-3vxVI0BhNz/9m59b+P2YEIrwGwlp7K3pyPKt4VqQuHE=";
            };
          });

          serve-app = pkgs.writeShellScriptBin "serve-app" ''
            ${pkgs.python3Minimal}/bin/python3 -m http.server --directory ${wasm} 8000
          '';
#          dockerImage = pkgs.dockerTools.buildImage {
#            name = "example_command_api";
#            tag = "latest";
#            copyToRoot = [ bin ];
#            config = {
#              Cmd = [ "${bin}/bin/dendrite_example" ];
#            };
#          };
        in
        with pkgs;
        {
          checks = {
            inherit wasm;
            wasm-clippy = craneLib.cargoClippy (commonArgs // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            });
            wasm-fmt = craneLib.cargoFmt {
              inherit src;
            };
          };
          packages = {
            inherit wasm;
            default = wasm;
          };
          apps.default = flake-utils.lib.mkApp {
            drv = serve-app;
          };
          devShells.default = craneLib.devShell {
            # Inherit inputs from checks.
            checks = self.checks.${system};

            # Additional dev-shell environment variables can be set directly
            # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

            # Extra inputs can be added here; cargo and rustc are provided by default.
            packages = [
              pkgs.trunk
              pkgs.wasm-bindgen-cli
            ] ++ buildInputs;
          };
        }
      );
}