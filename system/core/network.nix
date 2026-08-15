{
  networking = {
    networkmanager = {
      enable = true;
    };
    firewall.allowedTCPPorts = [
      22 # sshd
      6600 # mpd
    ];
    hosts = {
      "185.199.109.133" = [ "raw.githubusercontent.com" ];
      "185.199.111.133" = [ "raw.githubusercontent.com" ];
      "185.199.110.133" = [ "raw.githubusercontent.com" ];
      "185.199.108.133" = [ "raw.githubusercontent.com" ];
    };
  };
}
