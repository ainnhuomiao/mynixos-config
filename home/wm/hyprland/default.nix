{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./config.nix ];

  # 第二套独立 WM(Hyprland): 与 sway 完全平行, ly 登录选择。
  # 不设全局 sessionVariables — sway 模块的变量对 Hyprland 同样适用,
  # Hyprland 专属环境变量放在 hyprland.conf 的 env 段。
  home.packages = with pkgs; [
    hyprland
    hyprpaper
    # caelestia-shell 桌面 shell (bar/通知/锁屏/控制中心), 替代 Hyprland 会话的
    # waybar + mako; with-cli 变体提供 caelestia shell IPC 命令
    # 汉化: 应用 lib/caelestia-zh.nix 的 zh_CN patch (hdcy 字典)
    (import ../../../lib/caelestia-zh.nix { inherit inputs; system = pkgs.stdenv.hostPlatform.system; })
    # CLI 二进制独立 flake (caelestia-dots/cli), with-cli 只把它当运行时依赖不注入 PATH
    inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
