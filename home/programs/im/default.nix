{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      telegram-desktop
      wechat
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
