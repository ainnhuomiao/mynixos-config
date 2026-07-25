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
          wrapProgram $out/bin/wechat \
            --set QT_QPA_PLATFORM xcb \
            --set QT_IM_MODULE fcitx \
            --set GTK_IM_MODULE fcitx \
            --set XMODIFIERS @im=fcitx
        '';
      })

      qq
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
