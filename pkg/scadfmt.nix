{
  writeShellApplication,
  coreutils,
  scadformat,
}:
writeShellApplication {
  name = "scadfmt";

  runtimeInputs = [
    coreutils
    scadformat
  ];

  text = ''
    for file in "$@"; do
      formatted=$(mktemp "$file.XXXXXX")
      trap 'rm -f "$formatted"' EXIT

      scadformat --log-level error <"$file" >"$formatted"
      cmp -s "$formatted" "$file" || cat "$formatted" >"$file"
      rm -f "$formatted"
    done
  '';
}
