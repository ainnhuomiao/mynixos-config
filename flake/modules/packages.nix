{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.self.overlays.default ];
      };
    in
    {
      packages = {
        inherit (pkgs)
          bili_tui
          fcitx5-pinyin-moegirl
          fcitx5-pinyin-zhwiki
          flake-stats-mcp
          mcp-nixos
          motrix-next
          oh-my-pi-zh
          ;
        # zen-browser 来自 flake input，nixpkgs 没有，需一并缓存
        zen-browser = inputs.zen-browser.packages.${system}.default;
      };
    };
}
