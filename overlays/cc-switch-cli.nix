final: prev:

{
  cc-switch-cli = final.rustPlatform.buildRustPackage rec {
    pname = "cc-switch-cli";
    version = "5.9.2-unstable-2026-07-22";

    src = final.fetchFromGitHub {
      owner = "SaladDay";
      repo = "cc-switch-cli";
      rev = "98363c3ee32670d469d59be7941fd69972796073";
      hash = "sha256-mnooblcWWvnRkHKdaTSE9FN5ECuefl4LPCNF/ihP+Kc=";
    };

    cargoRoot = "src-tauri";
    buildAndTestSubdir = cargoRoot;
    cargoLock.lockFile = "${src}/src-tauri/Cargo.lock";

    doCheck = false;

    postInstall = ''
      mv $out/bin/cc-switch $out/bin/cc-switch-cli
    '';

    meta = with final.lib; {
      description = "Cross-platform CLI All-in-One assistant tool for Claude Code, Codex & Gemini CLI";
      homepage = "https://github.com/SaladDay/cc-switch-cli";
      license = licenses.mit;
      platforms = platforms.unix;
      mainProgram = "cc-switch-cli";
    };
  };
}
