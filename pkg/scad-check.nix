{
  writeShellApplication,
  coreutils,
  openscad-unstable,
  openscadLibraries,
}:
writeShellApplication {
  name = "scad-check";

  runtimeInputs = [
    coreutils
    openscad-unstable
  ];

  text = ''
    export OPENSCADPATH=${openscadLibraries}

    scratch=$(mktemp -d)
    trap 'rm -rf "$scratch"' EXIT

    status=0
    for file in "$@"; do
      openscad --hardwarnings -o "$scratch/check.csg" "$file" || status=1
    done

    exit "$status"
  '';
}
