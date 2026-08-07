{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "stl-3d-print-lint";
  version = "0.1.0";

  src = lib.cleanSource ./stl-3d-print-lint;

  cargoLock = {
    lockFile = ./stl-3d-print-lint/Cargo.lock;

    outputHashes = {
      "ansi-0.1.0" = "sha256-sstQowDd0onxnHylO4CjdTOZjHpmrRjh+0bJnHDZaAQ=";
    };
  };

  meta = {
    description = "lint stl meshes for 3d printing readiness";
    mainProgram = "stl-3d-print-lint";
  };
}
