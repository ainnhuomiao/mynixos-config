{ pkgs, ... }:
let
  wallpaperDirectory = ../../assets/wallpapers;
  sharedScripts = import ../programs/waybar/share_scripts.nix { inherit pkgs; };
in
{
  home.packages = [
    pkgs.mpvpaper
    pkgs.socat
  ];

  systemd.user.services = {
    swww = {
      Unit = {
        Description = "Efficient animated wallpaper daemon for wayland";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        ExecStop = "${pkgs.awww}/bin/awww kill";
        Restart = "always";
        RestartSec = 3;
      };
    };

    # mpvpaper 视频壁纸,由 video_wallpaper 切换脚本按需启动
    video-wall = {
      Unit = {
        Description = "mpvpaper video wallpaper";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
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
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
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
        BindsTo = [ "swww.service" ];
        After = [ "swww.service" ];
      };
      Install.WantedBy = [ "swww.service" ];
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
        ExecStart = ''${pkgs.awww}/bin/awww img "${wallpaperDirectory}/default.png" --transition-type random'';
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    swww-resume-fix = {
      Unit = {
        Description = "Fix swww wallpaper after resume";
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "swww-resume-fix" ''
          ${pkgs.dbus}/bin/dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" | \
          while read -r line; do
              if [[ "$line" == *"boolean false"* ]]; then
                  echo "Detected system resume, waiting for GPU and Wayland to settle..."
                  ${pkgs.coreutils}/bin/sleep 0.5
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
