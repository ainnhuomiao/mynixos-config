{
  nix.settings = {
    fallback = true;
    http-connections = 8;
    substituters = [
      "https://ainnhuomiao.qianyuanqing.asia/ainnhuomiao"
      "https://ainnhuomiao.cachix.org"
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    trusted-public-keys = [
      "ainnhuomiao:rSRSxFzka/Hu1R27mYg8TIE34+X9Vq4RA+orXAUr7U4="
      "ainnhuomiao.cachix.org-1:scMAjHS0YtCSBV0d6bbFWHDGD3BkPKuWbcfeWpqw5ck="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
}
