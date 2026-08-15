{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "3.16.0";
  # 运行时依赖（commander/undici，均无传递依赖）随插件自带 node_modules，
  # 与 `dsh plugin add @liustack/modlens` 的 pnpm 安装态保持一致
  commander = fetchurl {
    url = "https://registry.npmjs.org/commander/-/commander-13.1.0.tgz";
    sha256 = "sha256-1XA7ooUzbW1thv7Pep8GTiSIeUl9mMzJjKhJpi40gio=";
  };
  undici = fetchurl {
    url = "https://registry.npmjs.org/undici/-/undici-8.10.0.tgz";
    sha256 = "sha256-nXLFbBetKz1m8AbVOUU3TMDSvGjzIkOUlblyJp9N5rw=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "dsh-modlens";
  inherit version;

  # npm 官方发布的预构建 tarball（dist/、dsh/ 已构建），无需跑 npm 脚本
  src = fetchurl {
    url = "https://registry.npmjs.org/@liustack/modlens/-/modlens-${version}.tgz";
    sha256 = "sha256-jK8brvgnHt5kkj9tRXsSdAN4HIpNciCWV7tsLvOh9Zo=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    # npm tarball 顶层是 package/，剥掉一层后落到 $out
    tar xzf "$src" -C "$out" --strip-components=1
    mkdir -p "$out/node_modules/commander"
    tar xzf "${commander}" -C "$out/node_modules/commander" --strip-components=1
    mkdir -p "$out/node_modules/undici"
    tar xzf "${undici}" -C "$out/node_modules/undici" --strip-components=1
    chmod -R u+w "$out"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ModLens vision bridge for DeepSeek Harness: native read_image tool backed by configurable vision engines";
    homepage = "https://github.com/liustack/modlens";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
