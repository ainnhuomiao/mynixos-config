{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos";

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
    kernelParams = [
      "quiet"
      "splash"
    ];
  };

  services = {
    fstrim.enable = true;
    fwupd.enable = true;
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    mesa-demos
    libva-utils
  ];
}
