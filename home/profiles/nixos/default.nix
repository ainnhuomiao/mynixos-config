{ lib, config, ... }:
{
  imports = [
    ../../wall
    ../../shell
    ../../dev
    ../../editors/neovim
    ../../terminals
    ../../programs
    ../../ai
    ../../wm/sway
  ];

  wayland.windowManager.sway = lib.mkIf config.wayland.windowManager.sway.enable {
    extraOptions = [ "--unsupported-gpu" ];
  };

  programs.git.signing.signByDefault = lib.mkForce false;
}
