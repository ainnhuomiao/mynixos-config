{ appearance, config, ... }:
let
  cp = appearance.catppuccin.${appearance.catppuccinVariant};
  h = appearance.toHex;
in
{
  programs.kitty = {
    enable = true;
    font.name = appearance.font.name;
    font.size = 15;
    settings = {
      italic_font = "auto";
      bold_italic_font = "auto";
      mouse_hide_wait = 2;
      cursor_shape = "block";
      url_style = "dotted";
      confirm_os_window_close = 0;
      background_opacity = "0.85";
      dynamic_background_opacity = true;
      allow_remote_control = true;
      # 固定监听 socket, 供 theme-apply 热改运行中终端颜色
      listen_on = "unix:$XDG_RUNTIME_DIR/kitty-listen.sock";
    };
    extraConfig = ''
      # catppuccin ${appearance.catppuccinVariant} (切换: lib/appearance.nix 的 catppuccinVariant)
      foreground           ${h cp.fg}
      background           ${h cp.bg}
      selection_foreground #000000
      selection_background ${h cp.color8}
      url_color            ${h cp.color4}
      cursor               ${h cp.color4}

      color0  ${h cp.color0}
      color1  ${h cp.color1}
      color2  ${h cp.color2}
      color3  ${h cp.color3}
      color4  ${h cp.color4}
      color5  ${h cp.color5}
      color6  ${h cp.color6}
      color7  ${h cp.color7}
      color8  ${h cp.color8}
      color9  ${h cp.color9}
      color10 ${h cp.color10}
      color11 ${h cp.color11}
      color12 ${h cp.color12}
      color13 ${h cp.color13}
      color14 ${h cp.color14}
      color15 ${h cp.color15}

      # 当前主题(theme-apply 切换时覆盖), 缺失时用上面 mocha 默认值
      include ${config.home.homeDirectory}/.config/catppuccin/current/kitty-colors.conf
    '';
  };
}
