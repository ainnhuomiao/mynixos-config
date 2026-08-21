{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  version = "0.1.1";
  src = fetchFromGitHub {
    owner = "Anionex";
    repo = "dsh-turn-rewind";
    rev = "b1b85f18aaaaf71d76c84613429ce04d71f69620"; # main（npm 0.1.1 对应提交）
    hash = "sha256-oR/CwmY3EYg7e2jo8KE9F2HA86a6ETQjDVgI/Ri4JE4=";
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
