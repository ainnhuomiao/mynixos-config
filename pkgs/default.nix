{ inputs }:
{
  overlay = final: prev: {
    axolotl = final.callPackage ./axolotl { };
    bili_tui = final.callPackage ./bili_tui { };
    # dsh 改由 numtide/llm-agents.nix flake input 提供 (同为 rc.6 buildNpmPackage 配方,
    # 上游每日自动提版; 本地配方 pkgs/dsh 已删)
    dsh = inputs.llm-agents.packages.${final.system}.dsh;
    dsh-at-file = final.callPackage ./dsh-at-file { };
    dsh-modlens = final.callPackage ./dsh-modlens { };
    dsh-plugin-hub = final.callPackage ./dsh-plugin-hub { };
    dsh-tui = final.callPackage ./dsh-tui { };
    dsh-turn-rewind = final.callPackage ./dsh-turn-rewind { };
    dsh-web-search-tavily = final.callPackage ./dsh-web-search-tavily { };
    bun_1_3_14 = final.callPackage ./bun-1-3-14 { };
    fcitx5-pinyin-moegirl = final.callPackage ./fcitx5-pinyin-moegirl { };
    fcitx5-pinyin-zhwiki = final.callPackage ./fcitx5-pinyin-zhwiki { };
    flake-stats-mcp = final.callPackage ./flake-stats-mcp { };
    nordic = final.callPackage ./nordic { };
    oh-my-pi-zh = final.callPackage ./oh-my-pi-zh {
      bun2nix = inputs.bun2nix.packages.${final.system}.default;
      src = inputs.oh-my-pi-src;
      patchSrc = inputs.oh-my-pi-zh-src;
    };
    orca-ide = final.callPackage ./orca-ide { };
    # swayfx 0.6(窗口开合动画),nixpkgs 仍钉 0.5.3;复用 nixpkgs 的 sway wrapper
    swayfx = prev.sway.override {
      sway-unwrapped = inputs.swayfx.packages.${final.system}.swayfx-unwrapped-git;
    };
  };
}
