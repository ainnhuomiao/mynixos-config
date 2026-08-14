{ lib, appearance, ... }:

let
  mocha = appearance.catppuccin.mocha;
  # catppuccin/tty 的 16 色映射（themes/mocha.txt，tty.tera 顺序）：
  # color0 用 base 作内核控制台默认背景，color7 用 subtext1 作默认前景。
  # 颜色值全部取自本项目 lib/appearance.nix 的 catppuccin.mocha。
  ttyPalette = [
    mocha.bg # 0: base
    mocha.color1 # 1: red
    mocha.color2 # 2: green
    mocha.color3 # 3: yellow
    mocha.color4 # 4: blue
    mocha.color5 # 5: pink
    mocha.color6 # 6: teal
    mocha.color7 # 7: subtext1
    mocha.color8 # 8: surface1
    mocha.color1 # 9: bright red
    mocha.color2 # 10: bright green
    mocha.color3 # 11: bright yellow
    mocha.color4 # 12: bright blue
    mocha.color5 # 13: bright pink
    mocha.color6 # 14: bright teal
    mocha.color15 # 15: subtext0
  ];
  kmsconPaletteNames = [
    "palette-black"
    "palette-red"
    "palette-green"
    "palette-yellow"
    "palette-blue"
    "palette-magenta"
    "palette-cyan"
    "palette-light-grey"
    "palette-dark-grey"
    "palette-light-red"
    "palette-light-green"
    "palette-light-yellow"
    "palette-light-blue"
    "palette-light-magenta"
    "palette-light-cyan"
    "palette-white"
  ];
in
{
  services = {
    dbus.enable = true;
    openssh.enable = true;
    # 用户态 TTY 终端，pango+fontconfig 渲染，支持中文显示
    kmscon = {
      enable = true;
      config = {
        font-name = "Maple Mono NF CN, Noto Sans Mono CJK SC";
        font-size = 14;
        # Catppuccin Mocha 配色（kmscon.conf palette=custom + palette-* 键）
        palette = "custom";
        palette-foreground = appearance.toRgb mocha.fg;
        palette-background = appearance.toRgb mocha.bg;
      }
      // builtins.listToAttrs (
        lib.zipListsWith (name: color: {
          inherit name;
          value = appearance.toRgb color;
        }) kmsconPaletteNames ttyPalette
      );
    };
  };

  # 内核控制台（启动早期 + tty1 getty）用同一 Mocha 16 色调色板，
  # 由 console.colors 生成 vt.default_red/grn/blu 内核参数
  console.colors = ttyPalette;

  # ly 登录管理器(tty1)选择 sway / Hyprland, 不再需要 getty autologin;
  # kmscon 接管 VTs 2–6(中文 TTY)
  systemd.suppressedSystemUnits = lib.mkForce [ ];
  systemd.targets.getty.wants = lib.mkForce [ ];

  # stateVersion 记录首次安装时的 NixOS release(当前 stable: 26.05),升级后不要随意改动
  system.stateVersion = "26.05";
}
