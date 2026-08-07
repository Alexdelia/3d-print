{ pkgs, lib, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;

    ruff-format.enable = true;

    rustfmt = {
      enable = true;

      package = pkgs.rustToolchain;
    };

    shfmt = {
      enable = true;

      indent_size = 0;
    };
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
