{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      flclash
    ];
  };
}
