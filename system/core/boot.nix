{
  lib,
  enableLanzaboote ? false,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = lib.mkIf (!enableLanzaboote) {
        enable = true;
        efiSupport = true;
        device = "nodev";
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      timeout = 3;
    };
    lanzaboote = lib.mkIf enableLanzaboote {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
