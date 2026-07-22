{
  me,
  pkgs,
  ...
}:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  services.flatpak.enable = true;

  users.users.${me.userName}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    distrobox
    lazydocker
  ];
}
