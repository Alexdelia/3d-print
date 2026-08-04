{
  lib,
  buildGoModule,
  fetchFromGitHub,
  antlr4,
  indentSize ? 4,
}:
buildGoModule {
  pname = "scadformat";
  version = "0.9-unstable-2025-09-07";

  src = fetchFromGitHub {
    owner = "hugheaves";
    repo = "scadformat";
    rev = "7d2e0ec3ff65c1a2850fe37d0a33a3c519123824";
    hash = "sha256-RRJLeKoROMFWRTYAhue1aJ8baEy3hAkfNToCnIusb/0=";
  };

  vendorHash = "sha256-pGVU/XGY0uSPmMTVMbi5+mzjGN3b0NvA9vtvqXyGBv0=";

  nativeBuildInputs = [ antlr4 ];

  postPatch = ''
    echo "0.9-unstable-2025-09-07" > cmd/version.txt

    substituteInPlace internal/formatter/formatsettings.go \
      --replace-fail "indentSize: 2," "indentSize: ${toString indentSize},"

    antlr4 -o internal/parser -visitor -Dlanguage=Go OpenSCAD.g4
    patch -p0 --binary -i openscad_base_visitor.go.patch
  '';

  subPackages = [ "cmd" ];

  postInstall = ''
    mv $out/bin/cmd $out/bin/scadformat
  '';

  meta = {
    description = "Formatter for OpenSCAD source code";
    homepage = "https://github.com/hugheaves/scadformat";
    license = lib.licenses.gpl2Plus;
    mainProgram = "scadformat";
  };
}
