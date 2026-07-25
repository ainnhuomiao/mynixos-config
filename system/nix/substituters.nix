{
  nix.settings = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
}
