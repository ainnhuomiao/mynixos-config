{
  lib,
  buildNpmPackage,
  fetchurl,
  fetchNpmDeps,
  nodejs_22,
  jq,
}:

let
  version = "0.6.1";
in
buildNpmPackage {
  pname = "dsh-tui";
  inherit version;

  # npm 官方发布的预构建 tarball（lib/ 已 tsc 编译，含 bin/dsh-tui.js 与
  # cordis.patch.yml 自挂载 bundle patch），无需跑 npm run build
  src = fetchurl {
    url = "https://registry.npmjs.org/@deepseek-harness-tui/dsh-tui/-/dsh-tui-${version}.tgz";
    sha256 = "sha256-rsNf08wCSy5S0SNzxeUDGiAXGggpbrYONYHGM3Df004=";
  };

  nodejs = nodejs_22; # engines: ^22.19.0 || >=24.0.0

  npmDeps = fetchNpmDeps {
    src = ./.;
    hash = "sha256-7W/IHm4bVocRt2IMq+DA3ySxBwBXy23LbMsljkM9fa8=";
  };

  # dsh-tui 依赖 react ^19.2.0,而其传递依赖 dsh-working-activity 声明了
  # optional peer react ^18.2.0(host 侧代码不 import react,纯 npm 代数冲突)。
  # 真实安装即 pnpm autoInstallPeers:false 跳过 optional peer,这里等价物是
  # --legacy-peer-deps;锁文件也以同 flag 生成,与运行时语义一致。
  npmInstallFlags = [ "--legacy-peer-deps" ];

  nativeBuildInputs = [
    jq
    nodejs_22
  ];

  # lockfile 由「删除 devDependencies 后的 package.json」以
  # --legacy-peer-deps 生成(同 pkgs/dsh 方案):
  # - 避开 dev 依赖图(@types/tsx/typescript/…)与构建脚本
  # - npm ci 会校验 package.json 与 lockfile 的 root 一致性,这里同步删除
  postUnpack = ''
    cp ${./package-lock.json} $sourceRoot/package-lock.json
    jq 'del(.devDependencies)' $sourceRoot/package.json > $sourceRoot/package.json.tmp
    mv $sourceRoot/package.json.tmp $sourceRoot/package.json
  '';

  # tarball 无构建脚本(预构建),不跑 npm run build
  buildPhase = "true";

  # npm prune 会重解析 peer 图并尝试离线拉 cordis 元数据(ENOTCACHED);
  # install 已用预取缓存完成,prune 只是清理,跳过无副作用
  dontNpmPrune = true;

  meta = {
    description = "DeepSeek Harness Claude Code-style TUI: terminal front door consuming activity/status (working-activity)";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = lib.licenses.mit;
    mainProgram = "dsh-tui";
    platforms = lib.platforms.linux;
  };
}
