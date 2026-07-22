{
  programs = {
    fish.enable = true;
    git = {
      enable = true;
      config.safe.directory = [ "*" ];
    };
  };
}
