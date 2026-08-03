{ pkgs, inputs, ... }:
let
  sharedScripts = import ../../programs/waybar/share_scripts.nix { inherit pkgs; };
in
{
  imports = [ ./config.nix ];

  wayland.windowManager.sway = {
    enable = true;
    # package = inputs.nixpkgs-wayland.packages.${pkgs.stdenv.hostPlatform.system}.sway-unwrapped;
    wrapperFeatures.gtk = true;
  };
  home.packages = [
    inputs.hyprpicker.packages.${pkgs.stdenv.hostPlatform.system}.hyprpicker
    sharedScripts.wallpaper_random
    sharedScripts.dynamic_wallpaper
    sharedScripts.default_wall
  ]
  ++ (with pkgs; [
    swaylock
    sway-contrib.grimshot
    pamixer
    swayidle
    (pkgs.writeShellScriptBin "tt" ''
      STATUS=$(swaymsg -t get_inputs | jq -r '.[] | select(.type=="touchpad").libinput.send_events')
      if [[ "$STATUS" == "enabled" ]]; then
          swaymsg input "type:touchpad" events disabled
          notify-send "Touchpad disabled"
      else
          swaymsg input "type:touchpad" events enabled
          notify-send "Touchpad enabled"
      fi
    '')
  ]);

  systemd.user = {
    targets.sway-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  };

  home = {
    sessionVariables = {
      # 只让 wlroots 探测 Intel 卡:不打开 nvidia 的 DRM 节点,
      # 才能保证 nvidia 模块可热卸载(关坞电源前 modprobe -r)
      WLR_DRM_DEVICES = "/dev/dri/card0";
      QT_SCALE_FACTOR = "1";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_X11_NO_MITSHM = "1";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_DESKTOP = "sway";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
