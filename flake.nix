{
  description = "3d modeling for 3d printing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    bosl2 = {
      url = "github:BelfrySCAD/BOSL2";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      bosl2,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        openscadLibraries = pkgs.linkFarm "openscad-libraries" [
          {
            name = "BOSL2";
            path = bosl2;
          }
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            openscad-unstable
            openscad-lsp
            prusa-slicer
            f3d

            python3
          ];

          OPENSCADPATH = "${openscadLibraries}";
        };
      }
    );
}
