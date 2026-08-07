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

    ruff = {
      enable = true;
      stages = [ "pre-push" ];
    };

    ty = {
      enable = true;
      stages = [ "pre-push" ];

      name = "ty";
      description = "type check every python file";
      entry = "${lib.getExe pkgs.ty} check";
      files = "\\.py$";
    };

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

    rust-lint = {
      enable = true;
      stages = [ "pre-push" ];

      name = "rust-lint";
      description = "clippy the stl-3d-print-lint crate";
      entry = "cargo clippy --manifest-path pkg/stl-3d-print-lint/Cargo.toml --all-targets";
      files = "^pkg/stl-3d-print-lint/.*\\.rs$";
      pass_filenames = false;
    };

    rust-test = {
      enable = true;
      stages = [ "pre-push" ];

      name = "rust-test";
      description = "test the stl-3d-print-lint crate";
      entry = "cargo test --manifest-path pkg/stl-3d-print-lint/Cargo.toml";
      files = "^pkg/stl-3d-print-lint/.*\\.rs$";
      pass_filenames = false;
    };

    stl-3d-print-lint = {
      enable = true;
      stages = [ "pre-push" ];

      name = "stl-3d-print-lint";
      description = "check every stl for 3d printing readiness";
      entry = lib.getExe pkgs.stl-3d-print-lint;
      files = "\\.stl$";
    };
  };
}
