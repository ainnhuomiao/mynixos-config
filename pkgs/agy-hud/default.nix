{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  coreutils,
  gawk,
  git,
  gnugrep,
  gnused,
  jq,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "agy-hud";
  version = "0.2.3-unstable-2026-08-13";

  src = fetchFromGitHub {
    owner = "weby-homelab";
    repo = "antigravity-cli-statusline";
    rev = "cb33e555c129a240328b71eb34e61d3d8cdf7077";
    hash = "sha256-dwqgfJKGxX+Zsp/fwpB0iuT920SC2oQ/M2zFHq+d4X8=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/agy-hud $out/bin
    install -Dm755 statusline.sh $out/lib/agy-hud/statusline.sh

    makeWrapper ${bash}/bin/bash $out/bin/agy-hud \
      --add-flags "$out/lib/agy-hud/statusline.sh" \
      --add-flags "--medium-wide" \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          gawk
          git
          gnugrep
          gnused
          jq
        ]
      }
  '';

  meta = {
    description = "Adaptive telemetry statusline for Antigravity CLI";
    homepage = "https://github.com/weby-homelab/antigravity-cli-statusline";
    license = lib.licenses.mit;
    mainProgram = "agy-hud";
    platforms = lib.platforms.unix;
  };
}
