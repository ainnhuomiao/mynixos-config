{ ... }:
{
  programs.noctalia = {
    enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      # 视觉壁纸由 mpvpaper 渲染, Noctalia 不画壁纸层
      wallpaper = {
        enabled = false;
      };
      # 中文界面 (系统 locale 是 en_US, 默认会是英文)
      shell = {
        lang = "zh-Hans";
      };
    };
    # 不启用 systemd service: 用 sway exec 自启, 避免在 wayland socket 就绪前启动
  };
}
