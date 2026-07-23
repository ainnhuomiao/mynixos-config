{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      bilibili
      piliplus
    ];
  };
}
