{ lib, ... }:
{
  services.dae = {
    enable = true;
    configFile = ./dae.dae;
    openFirewall.enable = false;
  };

  systemd.services.dae = {
    after = [
      "mihomo.service"
      "network-online.target"
    ];
    requires = [ "mihomo.service" ];
    wants = [ "network-online.target" ];
    restartTriggers = [ ./dae.dae ];
  };

  networking.firewall.checkReversePath = lib.mkForce "loose";
}
