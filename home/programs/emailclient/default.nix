{ pkgs, ... }:
{
  home = {
    packages = [
      pkgs.thunderbird-bin
    ];
  };
}
