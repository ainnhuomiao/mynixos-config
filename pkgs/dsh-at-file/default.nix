{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
}:
let
  version = "0.4.0";
  src = fetchFromGitHub {
    owner = "omdsh-dev";
    repo = "dsh-at-file";
    rev = "d083071d12ef832b5bea6369e516c8d26b475096"; # tag v0.4.0
    hash = "sha256-4fQIPh37sY2qVIwuKlQ/o3dTUQ/jBs/wXpRKTu0YRIg=";
  };
  # 与 pnpm 安装态保持一致；lib/index.js 已被 esbuild 内联 zod，属防御性冗余
  zod = fetchurl {
    url = "https://registry.npmjs.org/zod/-/zod-4.4.3.tgz";
    sha256 = "sha256-7jjxf1M/1QBhBoWkg64vQTwm9OszpRaEMUVjyNYPJ5w=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "dsh-at-file";
  inherit version src;

  # 仓库提交了构建产物 lib/（README 明确：安装不需要包构建脚本），直接打包
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r "$src/lib" "$out/"
    cp "$src/package.json" "$src/cordis.patch.yml" "$src/dsh.plugin.json" "$out/"
    cp "$src/README.md" "$src/README.zh.md" "$src/LICENSE" "$out/"
    mkdir -p "$out/node_modules/zod"
    tar xzf "${zod}" -C "$out/node_modules/zod" --strip-components=1
    runHook postInstall
  '';

  meta = with lib; {
    description = "Codex-style @file mentions for the DeepSeek Harness web GUI: pick workspace paths in the composer";
    homepage = "https://github.com/omdsh-dev/dsh-at-file";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
