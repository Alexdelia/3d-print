{
  pkgs,
  lib,
  git-hooks,
  treefmt,
}:
git-hooks.run {
  src = ./.;

  hooks = {
    treefmt = {
      enable = true;
      stages = [ "pre-commit" ];

      packageOverrides.treefmt = treefmt;
    };

    deadnix = {
      enable = true;
      stages = [ "pre-push" ];
    };

    statix = {
      enable = true;
      stages = [ "pre-push" ];

      settings.format = "stderr";
    };

    # ruff = {
    #   enable = true;
    #   stages = [ "pre-push" ];
    # };

    shellcheck = {
      enable = true;
      stages = [ "pre-push" ];

      excludes = [ "^\\.envrc$" ];
    };

    scad-check = {
      enable = true;
      stages = [ "pre-push" ];

      name = "scad-check";
      description = "render every scad file, failing on warnings and assertions";
      entry = lib.getExe pkgs.scad-check;
      files = "\\.scad$";
    };
  };
}
