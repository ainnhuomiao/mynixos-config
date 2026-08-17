{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  dshHome = config.home.homeDirectory + "/.dsh";

  # 社区 agent preset（web 会话预设选择器用，部署到 ~/.dsh/.agent-presets/<id>/）。
  # 每个 preset 目录自包含（agent.cordis.yml 只引用 ./local.mjs，不透出 ../）。
  # 源 = flake inputs（更新: nix flake lock --update-input <name>）。
  presets = [
    {
      id = "anchored-standard";
      dir = "${inputs.dsh-anchored-standard}/preset";
    }
    {
      id = "router-standard";
      dir = "${inputs.dsh-router-standard}/preset/router-standard";
    }
    {
      id = "router-spec";
      dir = "${inputs.dsh-router-standard}/preset/router-spec";
    }
  ];

  # DSH 插件清单：dir = 插件在 profile node_modules 下的真实包名
  # （@scope 会落到对应子目录），drv = Nix 打包产物。
  # 新增插件：加一行清单 + 在下方 cordis.patch.yml 里加对应 insert。
  plugins = [
    {
      dir = "dsh-web-search-tavily";
      drv = pkgs.dsh-web-search-tavily;
    }
    {
      dir = "@liustack/modlens";
      drv = pkgs.dsh-modlens;
    }
    {
      dir = "dsh-at-file";
      drv = pkgs.dsh-at-file;
    }
    {
      dir = "@dsh-external/turn-rewind";
      drv = pkgs.dsh-turn-rewind;
    }
    {
      dir = "@deepseek-ai/dsh-plugin-console";
      drv = pkgs.dsh-plugin-hub;
    }
  ];
in
{
  home.packages = [
    pkgs.dsh
    pkgs.dsh-tui
  ];

  # ── dsh-tui profile(终端 TUI,与 web 平行)──────────────────────────────
  # 包 @deepseek-harness-tui/dsh-tui@0.6.1 自带 cordis.patch.yml 自挂载
  # bundle patch(覆盖 dsh-base 的各 tool/sandbox/approval 行 + insert
  # agent-presets/dsh-tui/working-activity 行),并 depends on
  # dsh-working-activity(经 ./working-activity 再导出挂载,不用裸包名——
  # pnpm 隔离 node_modules 下传递依赖进不了 profile 根)。
  # 因此本 profile 只需:bundles 声明 + node_modules 拷贝,无需手写 insert。
  home.file.".dsh/profiles/dsh-tui/package.json".text = ''
    {
      "name": "dsh-profile-dsh-tui",
      "private": true,
      "dependencies": {},
      "dsh": {
        "profile": {
          "bundles": [
            "@deepseek-ai/dsh-base",
            "@deepseek-harness-tui/dsh-tui"
          ]
        }
      }
    }
  '';

  # 与 web profile 同款 pnpm 配置(dsh plugin 转发 pnpm 时用)
  home.file.".dsh/profiles/dsh-tui/pnpm-workspace.yaml".text = ''
    packages:
      - .

    nodeLinker: hoisted
    autoInstallPeers: false
  '';

  # dsh-tui 包本体(含全部已装依赖树)+ host 树解析不覆盖的 peer(cordis 等
  # 由 dsh CLI 自身 node_modules 注入,与 web profile 的 dsh-base 同理)
  home.activation.installDshTui = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dst=${dshHome}/profiles/dsh-tui/node_modules/@deepseek-harness-tui/dsh-tui
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r ${pkgs.dsh-tui}/lib/node_modules/@deepseek-harness-tui/dsh-tui/. "$dst"/
    chmod -R u+w "$dst"
  '';

  # ── 插件补丁层（web profile 声明式配置）──────────────────────────────────
  # 各 insert 等价于 `dsh plugin add` 时插件自带 dsh.bundle.patch
  # （cordis.patch.yml）合并进 profile 补丁层的内容。
  # Tavily：把 web seam 的 searchProvider 从 deepseek-official 切换为 tavily，
  # TAVILY_API_KEY 走 DSH 自己的凭据文件 (~/.dsh/.credentials.yaml，不进 Nix 仓库)。
  home.file.".dsh/profiles/web/cordis.patch.yml".text = ''
    # 本文件由 home-manager 声明式管理（home/programs/dsh/default.nix）

    # ── Tavily 联网搜索 ──
    - insert:
        - id: web-search-tavily
          name: 'dsh-web-search-tavily'
          config:
            apiKeyEnv: TAVILY_API_KEY

    - id: web
      config:
        searchProvider: tavily

    # ── ModLens 视觉桥（read_image，引擎配置在 ~/.modlens）──
    - insert:
        - id: modlens
          name: '@liustack/modlens'

    # ── @文件 引用（composer 输入 @ 选文件/目录）──
    - insert:
        - id: dsh-at-file
          name: dsh-at-file

    # ── 回合回退（Change Ledger 驱动的对话/工作区回退）──
    - insert:
        - id: turn-rewind
          name: '@dsh-external/turn-rewind'

    # ── 插件控制台（Settings → Plugins）──
    - insert:
        - id: plugin-console
          name: '@deepseek-ai/dsh-plugin-console'
  '';

  # 插件本体以真实目录放入 profile 的 node_modules：Node 解析 peer 依赖
  # (@deepseek-ai/dsh-web 等) 需要沿真实路径向上回溯到 profile 的 hoisted
  # node_modules，所以用拷贝而非符号链接（store 路径在 profile 树之外）。
  # 运行 `dsh plugin --profile web <pnpm ...>` 可能清掉该目录，重跑
  # `just rebuild-switch` 即可恢复。
  # preset 用真实拷贝而非符号链接（与插件同理：store 路径在 profile 树外，
  # 节点解析会沿真实路径回溯失败）。activation 每次 rm -rf 后整目录重拷。
  home.activation.installDshPresets = lib.hm.dag.entryAfter [ "installDshPlugins" ] (
    lib.concatMapStrings (p: ''
      dst=${dshHome}/.agent-presets/${p.id}
      rm -rf "$dst"
      mkdir -p "$(dirname "$dst")"
      cp -r ${p.dir} "$dst"/
      chmod -R u+w "$dst"
    '') presets
  );

  home.activation.installDshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (p: ''
      dst=${dshHome}/profiles/web/node_modules/${p.dir}
      rm -rf "$dst"
      mkdir -p "$(dirname "$dst")"
      cp -r ${p.drv}/. "$dst"/
      chmod -R u+w "$dst"
    '') plugins
  );
}
