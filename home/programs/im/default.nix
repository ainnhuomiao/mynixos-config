{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      telegram-desktop
      (pkgs.symlinkJoin {
        name = "wechat";
        paths = [ pkgs.wechat ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          # wayland 原生: xcb 在 scale 1.25 下经 XWayland 渲染模糊
          wrapProgram $out/bin/wechat \
            --set QT_QPA_PLATFORM wayland \
            --set QT_IM_MODULE fcitx \
            --set GTK_IM_MODULE fcitx \
            --set XMODIFIERS @im=fcitx
        '';
      })

      # QQ (Electron): 包装自带 --ozone-platform-hint=auto 且命令行优先于环境变量,
      # 必须显式 --ozone-platform=wayland 才能走 Wayland 原生 (XWayland 1.25 下模糊)
      (pkgs.writeShellScriptBin "qq" ''
        exec ${pkgs.qq}/bin/qq --ozone-platform=wayland "$@"
      '')

      (feishu.override {
        nss = nss_latest; # Fix issue where Feishu documents cannot be opened due to NSS version mismatch
      })
      wemeet
      # nur.repos.linyinfeng.icalingua-plus-plus
      vesktop
      (element-desktop.override {
        commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=x11";
      })
    ];
  };
}
