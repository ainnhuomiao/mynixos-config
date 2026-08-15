{
  pkgs,
  me,
  ...
}:
{
  programs.wshowkeys.enable = true;
  programs = {
    dconf.enable = true;
  };

  programs.nm-applet = {
    enable = true;
    indicator = true;
  };

  services.blueman.enable = true;

  security.pam.services.swaylock = { };
  xdg.portal = {
    enable = true;
    config = {
      sway = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
      hyprland = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      };
    };
    wlr = {
      enable = true;
      settings.screencast.chooser_type = "none";
    };
    configPackages = [ pkgs.gnome-session ];
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      libnotify
      wl-clipboard
      cliphist
      wlr-randr
      wf-recorder
      wlprop
      xeyes
      nemo
      wev
      pulsemixer
      sshpass
      imagemagick
      chafa
      grim
      slurp
      satty
      linux-wifi-hotspot
      scrcpy
      gource
      vscode
      blender
      s-search
      gparted
      brightnessctl
      # XWayland 高清渲染 (Xft.dpi 加载工具)
      xorg.xrdb
    ];
    variables.NIXOS_OZONE_WL = "1";
  };

  services = {
    dbus.packages = [ pkgs.gcr ];
    gvfs.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  # ly 登录管理器已拆分为独立模块 ./ly.nix
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
