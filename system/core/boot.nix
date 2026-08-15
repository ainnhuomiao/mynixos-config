{
  lib,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
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
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
