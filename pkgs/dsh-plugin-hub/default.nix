{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  version = "0.1.0-rc.6";
  src = fetchFromGitHub {
    owner = "Noob-stupid";
    repo = "dsh-plugin-hub";
    rev = "6e7c8682b235ae0dd1b1c3e7dadeeea17c3b37e6"; # main（仓库暂无 tag）
    hash = "sha256-Hzb74q/57c468qXjWhU8jDnMjx+spU1gJRyH1mIbBts=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "dsh-plugin-hub";
  inherit version src;

  # 纯 JS 已构建（lib/ 提交在仓库中，无依赖、无构建脚本）
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r "$src/lib" "$out/"
    cp "$src/package.json" "$src/cordis.patch.yml" "$out/"
    cp "$src/README.md" "$src/LICENSE" "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Plugin console for DeepSeek Harness: browse and install GitHub dsh-plugin plugins from Settings";
    homepage = "https://github.com/Noob-stupid/dsh-plugin-hub";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
