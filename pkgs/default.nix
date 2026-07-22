{
  overlay = final: _prev: {
    bili_tui = final.callPackage ./bili_tui { };
    fcitx5-pinyin-moegirl = final.callPackage ./fcitx5-pinyin-moegirl { };
    fcitx5-pinyin-zhwiki = final.callPackage ./fcitx5-pinyin-zhwiki { };
    flake-stats-mcp = final.callPackage ./flake-stats-mcp { };
  };
}
