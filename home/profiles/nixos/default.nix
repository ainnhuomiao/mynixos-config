{ lib, config, ... }:
{
  imports = [
    ../../wall
    ../../shell
    ../../dev
    ../../editors/neovim
    ../../editors/vscode.nix
    ../../terminals
    ../../programs
    ../../ai
    ../../wm/sway
    ../../wm/hyprland
  ];

  wayland.windowManager.sway = lib.mkIf config.wayland.windowManager.sway.enable {
    extraOptions = [ "--unsupported-gpu" ];
  };
}
