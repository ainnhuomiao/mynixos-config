{ pkgs, lib, ... }:
let
  wallpaperDirectory = ../../assets/wallpapers;
  sharedScripts = import ./share_scripts.nix { inherit pkgs; };
in
{
  home.packages = [
    pkgs.mpvpaper
    pkgs.socat
  ];

  systemd.user.services = {
    awww = {
      Unit = {
        Description = "Efficient animated wallpaper daemon for wayland";
        # 壁纸服务只属于 sway 会话: graphical-session.target 常驻不停止,
        # 模式同 waybar/swayidle (会话结束不风暴重启)。
        PartOf = lib.mkForce [ "sway-session.target" ];
        After = [ "graphical-session.target" ];
      };
      # 默认壁纸是视频(video-wall 随会话启动),awww 只在切换到静态时
      # 由 wallpaper_* / video_wallpaper 脚本按需 start,不再随登录自启。
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        ExecStop = "${pkgs.awww}/bin/awww kill";
        # 同 swayidle: awww 是 wayland 客户端, 会话结束时随断连退出,
        # Restart=always 会风暴重启。
        Restart = "no";
      };
    };

    # mpvpaper 视频壁纸:默认壁纸,随 sway 会话自动启动;
    # 切静态由 video_wallpaper 脚本 stop,切回视频再 start。
    video-wall = {
      Unit = {
        Description = "mpvpaper video wallpaper";
        PartOf = lib.mkForce [ "sway-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = lib.mkForce [ "sway-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${sharedScripts.video_wallpaper_play}/bin/video_wallpaper_play";
        Restart = "no";
      };
    };

    # 休眠时暂停视频壁纸,唤醒后恢复(通过 mpvpaper 的 IPC socket)
    video-wall-resume = {
      Unit = {
        Description = "Pause/resume mpvpaper around suspend";
        PartOf = lib.mkForce [ "sway-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = lib.mkForce [ "sway-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "video-wall-resume" ''
          ${pkgs.dbus}/bin/dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" | \
          while read -r line; do
              if [[ "$line" == *"boolean true"* ]]; then
                  echo 'set pause yes' | ${pkgs.socat}/bin/socat - /tmp/mpvpaper.sock || true
              elif [[ "$line" == *"boolean false"* ]]; then
                  echo 'set pause no' | ${pkgs.socat}/bin/socat - /tmp/mpvpaper.sock || true
              fi
          done
        '';
        Restart = "always";
        RestartSec = 5;
      };
    };

    default_wall = {
      Unit = {
        Description = "default wallpaper";
        BindsTo = [ "awww.service" ];
        After = [ "awww.service" ];
      };
      Install.WantedBy = [ "awww.service" ];
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
        ExecStart = ''${pkgs.awww}/bin/awww img "${wallpaperDirectory}/default.png" --transition-type random'';
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    awww-resume-fix = {
      Unit = {
        Description = "Fix awww wallpaper after resume";
        PartOf = lib.mkForce [ "sway-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = lib.mkForce [ "sway-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "awww-resume-fix" ''
          ${pkgs.dbus}/bin/dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" | \
          while read -r line; do
              if [[ "$line" == *"boolean false"* ]]; then
                  echo "Detected system resume, waiting for GPU and Wayland to settle..."
                  ${pkgs.coreutils}/bin/sleep 0.5
                  # 默认视频壁纸时 awww 不运行,只有静态模式才需要重刷壁纸
                  ${pkgs.systemd}/bin/systemctl --user is-active --quiet awww.service && \
                    ${pkgs.systemd}/bin/systemctl --user restart default_wall
              fi
          done
        '';
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
