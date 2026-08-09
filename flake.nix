{
  description = "huomiao's NixOS Configuration";

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./flake/modules
        ./hosts
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
    };

  inputs = {
    # update single input: `nix flake lock --update-input <name>`
    # update all inputs: `nix flake update`
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-shell = {
      # 本地汉化副本已推送到 GitHub (ainnhuomiao/caelestia-shell-zh):
      # hdcy/Caelestia_Shell_zh_CN 字典(647/659 词条) + 12 汉化补丁 + 2 bug 修复
      # 上游 rev 817a220。重新生成: rm -rf caelestia-shell-zh && python3 ~/hanhua_drive.py
      # (脚本会复制上游 -> 汉化 -> git 提交; 之后 git push + nix flake lock --update-input caelestia-shell)
      url = "github:ainnhuomiao/caelestia-shell-zh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emanote = {
      url = "github:srid/emanote";
      # emanote 的 Haskell 依赖 fsnotify-0.4.1.0 要求 text < 2.1.2，
      # 故锁在 nixpkgs-emanote（6b49552），顶层 nixpkgs 可自由更新
      inputs.nixpkgs.follows = "nixpkgs-emanote";
    };
    nixpkgs-emanote.url = "github:nixos/nixpkgs/6b4955211758ba47fac850c040a27f23b9b4008f";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    flake-registry = {
      url = "github:NixOS/flake-registry";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr.url = "github:ogulcancelik/herdr";
    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    oh-my-pi-src = {
      url = "github:can1357/oh-my-pi/v17.1.7";
      flake = false;
    };
    oh-my-pi-zh-src = {
      url = "github:LiuQingHuaYang/oh-my-pi-zh/v17.1.7";
      flake = false;
    };
    nur.url = "github:nix-community/NUR";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    selector4nix.url = "github:StarryReverie/selector4nix";
    swayfx = {
      url = "github:WillPower3309/swayfx/0.6";
      # 0.6 起才有 animation_duration_ms(窗口开合动画),nixpkgs 仍钉 0.5.3
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    zen-browser = {
      url = "git+https://github.com/youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    fallback = true;
    http-connections = 16;
    extra-substituters = [
      "https://ainnhuomiao.qianyuanqing.asia/ainnhuomiao"
      "https://ainnhuomiao.cachix.org"
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
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
