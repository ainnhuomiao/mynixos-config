{ pkgs, appearance, ... }:
let
  t = appearance.palettes.tokyoNight;
  h = appearance.toHex;
in
{
  home = {
    packages = with pkgs; [
      fd
      ripgrep
    ];
  };
  programs = {
    fzf = {
      enable = true;
      colors = {
        "bg" = h t.bg;
        "bg+" = h t.sel_bg;
        "fg" = h t.fg;
        "fg+" = h t.fg;
        "hl" = h t.red;
        "hl+" = h t.red;
        "info" = h t.purple;
        "prompt" = h t.purple;
        "pointer" = h t.orange;
        "marker" = h t.orange;
        "spinner" = h t.orange;
        "header" = h t.red;
        "border" = h t.purple;
      };
    };
    bat = {
      enable = true;
      config.theme = "Nord";
    };
  };

  imports = [
    ./s.nix
  ];
}
