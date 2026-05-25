{ pkgs, ... }:
{
  imports = [
    ./fish
    ./starship.nix
    ./eza.nix
  ];
  home.packages = [ pkgs.tree ];
}
