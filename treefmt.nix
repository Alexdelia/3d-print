{ pkgs, lib, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;

    # ruff-format.enable = true;

    shfmt.enable = true;
  };

  settings = {
    formatter.scadformat = {
      command = lib.getExe pkgs.scadfmt;
      includes = [ "*.scad" ];
    };

    excludes = [
      ".gitignore"
      ".envrc"
      "*.stl"
      "*.3mf"
      "*.zip"
    ];
  };
}
