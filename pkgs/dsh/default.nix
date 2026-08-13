{
  lib,
  buildNpmPackage,
  fetchurl,
  fetchNpmDeps,
  nodejs_22,
  makeWrapper,
  python3,
  gnumake,
  gcc,
  jq,
}:

let
  version = "0.1.0-rc.6";
in
buildNpmPackage {
  pname = "dsh";
  inherit version;

  # npm 官方发布的预构建 tarball（lib/*.js 已构建，含 config/agent-presets）
  src = fetchurl {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${version}.tgz";
    sha256 = "sha256-G4qaCtPH/q7OR5JuC9N8oVHHzPqZeVOvpf0BJheE6tw=";
  };

  nodejs = nodejs_22; # engines: ^22.19.0 || >=24.0.0

  npmDeps = fetchNpmDeps {
    src = ./.;
    hash = "sha256-+fvLPBlLWujF1Iv+LMZ8EMP3M/+HBE7s6Djtrao7fxI=";
  };

  nativeBuildInputs = [
    makeWrapper
    python3 # node-pty node-gyp 编译
    gnumake
    gcc
    jq
    nodejs_22
  ];

  # 运行时 node-gyp 用本地头文件，避免构建时从 nodejs.org 下载
  npm_config_nodedir = "${nodejs_22}";

  # lockfile 由「删除 devDependencies 后的 package.json」生成：
  # - 避开 dev 依赖图（execa/@types/…）与 postinstall 下载
  # - npm ci 会校验 package.json 与 lockfile 的 root 一致性，这里同步删除
  # - devDependencies 里没有运行时需要的包（web 静态资源走 @deepseek-ai/dsh-web-frontend 生产依赖）
  postUnpack = ''
    cp ${./package-lock.json} $sourceRoot/package-lock.json
    jq 'del(.devDependencies)' $sourceRoot/package.json > $sourceRoot/package.json.tmp
    mv $sourceRoot/package.json.tmp $sourceRoot/package.json
  '';

  # tarball 无 scripts（预构建），不跑 npm run build
  buildPhase = "true";

  # cordis-plugin-hmr 要求 node 带 --expose-internals（检测 ctx.loader.internal），
  # 且 NODE_OPTIONS 白名单不允许该 flag → 必须直接 exec node --expose-internals
  # （不能 wrapProgram --add-flags，那会把 flag 传给 dsh CLI 而不是 node）
  postInstall = ''
    rm -f $out/bin/dsh $out/bin/.dsh-wrapped
    makeWrapper ${nodejs_22}/bin/node "$out/bin/dsh" \
      --add-flags "--expose-internals" \
      --add-flags "$out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_22 ]}
  '';

  meta = {
    description = "DeepSeek Harness CLI: everything is a plugin agent harness";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.linux;
  };
}
