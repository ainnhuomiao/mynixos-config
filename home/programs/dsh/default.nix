{
  pkgs,
  config,
  lib,
  ...
}:
let
  dshHome = config.home.homeDirectory + "/.dsh";

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
  home.packages = [ pkgs.dsh ];

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
