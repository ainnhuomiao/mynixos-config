{ inputs }:
{
  overlay = final: _prev: {
    bili_tui = final.callPackage ./bili_tui { };
    bun_1_3_14 = final.callPackage ./bun-1-3-14 { };
    fcitx5-pinyin-moegirl = final.callPackage ./fcitx5-pinyin-moegirl { };
    fcitx5-pinyin-zhwiki = final.callPackage ./fcitx5-pinyin-zhwiki { };
    flake-stats-mcp = final.callPackage ./flake-stats-mcp { };
    oh-my-pi-zh = final.callPackage ./oh-my-pi-zh {
      bun2nix = inputs.bun2nix.packages.${final.system}.default;
      src = inputs.oh-my-pi-src;
      patchSrc = inputs.oh-my-pi-zh-src;
    };
  };
}
