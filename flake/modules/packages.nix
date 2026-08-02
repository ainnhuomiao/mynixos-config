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
          bilibili
          bili_tui
          claude-code
          discord
          element-desktop
          fcitx5-pinyin-moegirl
          fcitx5-pinyin-zhwiki
          feishu
          flake-stats-mcp
          github-copilot-cli
          google-chrome
          mcp-nixos
          microsoft-edge
          motrix-next
          nordic
          obsidian
          oh-my-pi-zh
          qq
          thunderbird-bin
          vscode
          wechat
          wemeet
          ;
        # zen-browser 来自 flake input，nixpkgs 没有，需一并缓存
        zen-browser = inputs.zen-browser.packages.${system}.default;
      };
    };
}
