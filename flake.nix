{
  description = "3d modeling for 3d printing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

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
            (final: _prev: {
              openscadLibraries = final.linkFarm "openscad-libraries" [
                {
                  name = "BOSL2";
                  path = bosl2;
                }
              ];

              scadformat = final.callPackage ./pkg/scadformat.nix { };
              scadfmt = final.callPackage ./pkg/scadfmt.nix { };
              scad-check = final.callPackage ./pkg/scad-check.nix { };
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

        devShells.default = pkgs.mkShell {
          inherit (preCommit) shellHook;

          buildInputs = preCommit.enabledPackages;

          packages = with pkgs; [
            openscad-unstable
            openscad-lsp
            prusa-slicer
            f3d

            python3

            scadformat
            scad-check
          ];

          OPENSCADPATH = "${pkgs.openscadLibraries}";
        };
      }
    );
}
