{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.self.overlays.default ];
        # 与系统配置一致：允许 unfree / broken / unsupported 包
        config = {
          allowUnfree = true;
          allowBroken = true;
          allowUnsupportedSystem = true;
        };
      };
    in
    {
      packages = {
        inherit (pkgs)
          axolotl
          bilibili
          bili_tui
          claude-code
          cloudflare-speedtest
          discord
          dsh
          dsh-at-file
          dsh-modlens
          dsh-plugin-hub
          dsh-tui
          dsh-turn-rewind
          dsh-web-search-tavily
          element-desktop
          fcitx5-pinyin-moegirl
          fcitx5-pinyin-zhwiki
          feishu
          flake-stats-mcp
          github-copilot-cli
          google-chrome
          hmcl
          mcp-nixos
          microsoft-edge
          motrix-next
          nordic
          obsidian
          oh-my-pi-zh
          orca-ide
          qq
          swayfx
          steam
          thunderbird-bin
          v2rayn
          vscode
          wechat
          wemeet
          ;
        # caelestia-shell/cli 来自 flake input, nixpkgs 没有, 需一并缓存
        # (with-cli 与系统 home 配置一致, 闭包含 quickshell/qml-plugin/extras/m3shapes)
        # 汉化: 应用 lib/caelestia-zh.nix 的 zh_CN patch (hdcy 字典)
        caelestia-shell = import ../../lib/caelestia-zh.nix { inherit inputs system; };
        caelestia-cli = inputs.caelestia-cli.packages.${system}.default;
        # zen-browser 来自 flake input，nixpkgs 没有，需一并缓存
        zen-browser = inputs.zen-browser.packages.${system}.default;
        # reasonix/antigravity-cli 来自 numtide/llm-agents.nix input（dsh 同源，
        # 经 pkgs 的 overlay 以 pkgs.dsh 暴露，见 pkgs/default.nix）
        reasonix = inputs.llm-agents.packages.${system}.reasonix;
        antigravity-cli = inputs.llm-agents.packages.${system}.antigravity-cli;
      };
    };
}
