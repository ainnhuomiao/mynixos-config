final: prev:

{
  cc-switch = final.stdenv.mkDerivation rec {
    pname = "cc-switch";
    version = "5.9.0";

    src = final.fetchurl {
      url = "https://github.com/SaladDay/cc-switch-cli/releases/download/v${version}/cc-switch-cli-linux-x64-musl.tar.gz";
      hash = "sha256-3DOC3U9rijzpv5nbhbcib3uj/KA4Ge8RVgmDLN+nh4I=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ final.autoPatchelfHook ];
    buildInputs = [ final.stdenv.cc.cc.lib ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -Dm755 cc-switch $out/bin/cc-switch
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Cross-platform CLI All-in-One assistant tool for Claude Code, Codex & Gemini CLI";
      homepage = "https://github.com/SaladDay/cc-switch-cli";
      license = licenses.mit;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "cc-switch";
    };
  };
}
