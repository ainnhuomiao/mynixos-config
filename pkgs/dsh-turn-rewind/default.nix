{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "Anionex";
    repo = "dsh-turn-rewind";
    rev = "944b1ac8f6b170b55b692a51ddfa3a09f1b97ff1"; # main（仓库暂无 tag）
    hash = "sha256-apDvanZKjx9ATYopaHmNJwfeI0kUwSbnpyXyIroe7Yo=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "dsh-turn-rewind";
  inherit version src;

  # 纯 JS 已构建（lib/ 提交在仓库中，仅 node: 内建 + 相对导入，无运行时依赖；
  # @deepseek-ai/cordis 走 peer 依赖，由 profile/harness 的 hoisted node_modules 解析）
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r "$src/lib" "$out/"
    cp "$src/package.json" "$src/cordis.patch.yml" "$out/"
    cp "$src/README.md" "$src/README.zh.md" "$src/LICENSE" "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Turn-level conversation and workspace rewind for DeepSeek Harness, powered by a persistent Change Ledger";
    homepage = "https://github.com/Anionex/dsh-turn-rewind";
    license = licenses.bsd3;
    platforms = platforms.all;
  };
}
