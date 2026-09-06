{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos";

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
    kernelParams = [
      "quiet"
      "splash"
      # Iris Xe (8086:a7a0) 改用新的 xe 驱动(本内核需 force_probe 才接管);
      # 同时取反阻止 i915 抢占绑定
      "xe.force_probe=a7a0"
      "i915.force_probe=!a7a0"
    ];
  };

  services = {
    fstrim.enable = true;
    fwupd.enable = true;
    upower.enable = true;
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
