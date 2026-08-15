{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "dsh-web-search-tavily";
  version = "0.1.0";

  # 纯 JS 无构建步骤：直接打包源码
  src = ./.;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp package.json "$out/"
    cp -r lib "$out/"
    cp README.md "$out/" 2>/dev/null || true
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tavily-backed search provider (ctx.web) for the DeepSeek Harness";
    homepage = "https://tavily.com";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
