{
  # selector4nix: local substituter proxy with latency-aware selection
  # It prepends itself to the substituter list; upstream fallbacks stay intact.
  services.selector4nix = {
    enable = true;
    enablePersistentCaching = true;
    # "prepend": proxy first, original substituters as fallback (safe if proxy dies)
    configureSubstituter = "prepend";

    settings = {
      server = {
        ip = "127.0.0.1";
        # port = 5496; # Default port
      };

      substituters = [
        { url = "https://cache.nixos.org/"; }
        { url = "https://ainnhuomiao.qianyuanqing.asia/ainnhuomiao"; }
        { url = "https://ainnhuomiao.cachix.org"; }
        { url = "https://nix-community.cachix.org"; }
        { url = "https://attic.xuyh0120.win/lantian"; }
        { url = "https://cache.numtide.com/"; }
        {
          # USTC mirror of cache.nixos.org; higher priority = lower precedence
          url = "https://mirrors.ustc.edu.cn/nix-channels/store/";
          priority = 45;
        }
      ];
    };
  };

  nix.settings = {
    fallback = true;
    http-connections = 16;
    max-substitution-jobs = 32;
    substituters = [
      "https://ainnhuomiao.qianyuanqing.asia/ainnhuomiao"
      "https://ainnhuomiao.cachix.org"
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "ainnhuomiao:rSRSxFzka/Hu1R27mYg8TIE34+X9Vq4RA+orXAUr7U4="
      "ainnhuomiao.cachix.org-1:scMAjHS0YtCSBV0d6bbFWHDGD3BkPKuWbcfeWpqw5ck="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
}
