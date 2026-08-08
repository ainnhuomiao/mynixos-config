{ pkgs, ... }:
{
  home.packages = [
    pkgs.axolotl
    pkgs.jdk21
  ];
}
