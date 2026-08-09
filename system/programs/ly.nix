{
  pkgs,
  ...
}:
{
  # ly 登录管理器: tty1 选择 sway / Hyprland。
  # 会话经 bash -lc 启动(加载 NixOS /etc/profile 链, 含 hm sessionVariables),
  # wrapper 在 systemPackages 里 (/run/current-system/sw/bin/ly-*)。
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "dur_file";
      dur_file_path = "/etc/ly/blackhole-smooth-240x67.dur";
      # 黑洞动画是 256 色编码, ly 默认八色模式会拒绝加载
      full_color = true;
    };
  };

  services.displayManager.sessionPackages = [
    (pkgs.runCommand "ly-sessions"
      {
        providedSessions = [
          "sway"
          "hyprland"
        ];
      }
      ''
        mkdir -p $out/share/wayland-sessions
        cat > $out/share/wayland-sessions/sway.desktop <<EOF
        [Desktop Entry]
        Name=Sway
        Comment=Swayfx (Wayland)
        Exec=/run/current-system/sw/bin/ly-sway
        Type=Application
        EOF
        cat > $out/share/wayland-sessions/hyprland.desktop <<EOF
        [Desktop Entry]
        Name=Hyprland
        Comment=Hyprland (Wayland)
        Exec=/run/current-system/sw/bin/ly-hyprland
        Type=Application
        EOF
      ''
    )
  ];

  # 黑洞动画 (ly-community blackhole-smooth-240x67):
  # 固定路径放 /etc/ly/ (pathsToLink 链接的文件名带 store hash, 不适合引用)
  environment.etc."ly/blackhole-smooth-240x67.dur".source =
    ../../assets/ly/blackhole-smooth-240x67.dur;

  environment.systemPackages = [
    # ly 会话包装: 经 login shell 加载 hm sessionVariables (WLR_DRM_DEVICES 等)
    (pkgs.writeShellScriptBin "ly-sway" ''
      exec ${pkgs.bash}/bin/bash -lc "exec sway"
    '')
    (pkgs.writeShellScriptBin "ly-hyprland" ''
      # start-hyprland: Hyprland 官方启动包装 (消除 "started without start-hyprland" 警告)
      exec ${pkgs.bash}/bin/bash -lc "exec start-hyprland"
    '')
  ];
}
