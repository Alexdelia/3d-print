{
  description = "3d modeling for 3d printing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bosl2 = {
      url = "github:BelfrySCAD/BOSL2";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      treefmt-nix,
      git-hooks,
      bosl2,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            (import rust-overlay)

            (final: _prev: {
              openscadLibraries = final.linkFarm "openscad-libraries" [
                {
                  name = "BOSL2";
                  path = bosl2;
                }
              ];

              rustToolchain = final.rust-bin.stable.latest.default.override {
                extensions = [ "rust-analyzer" ];
              };

              scadformat = final.callPackage ./pkg/scadformat.nix { };
              scadfmt = final.callPackage ./pkg/scadfmt.nix { };
              scad-check = final.callPackage ./pkg/scad-check.nix { };
              stl-3d-print-lint = final.callPackage ./pkg/stl-3d-print-lint.nix {
                rustPlatform = final.makeRustPlatform {
                  cargo = final.rustToolchain;
                  rustc = final.rustToolchain;
                };
              };
            })
          ];
        };

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        preCommit = import ./hooks.nix {
          inherit pkgs;
          inherit (pkgs) lib;
          git-hooks = git-hooks.lib.${system};
          treefmt = treefmtEval.config.build.wrapper;
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks.pre-commit = preCommit;

        packages = {
          inherit (pkgs) scad-check stl-3d-print-lint;
        };

        devShells.default = pkgs.mkShell {
          inherit (preCommit) shellHook;

          buildInputs = preCommit.enabledPackages;

          packages = with pkgs; [
            openscad-unstable
            openscad-lsp
            prusa-slicer
            f3d

            imagemagick

            python3
            ruff
            ty

            rustToolchain

            scadformat
            scad-check
            stl-3d-print-lint
          ];

          OPENSCADPATH = "${pkgs.openscadLibraries}";
        };
      }
    );
}
