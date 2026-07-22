{ pkgs, ... }:
{
  xdg.configFile."clashtui/config.yaml" = {
    force = true;
    text = ''
      basic:
        clash_config_dir: /var/lib/mihomo-config
        clash_bin_path: ${pkgs.mihomo}/bin/mihomo
        clash_config_path: /var/lib/mihomo-config/config.yaml
        timeout: null
      service:
        clash_srv_name: mihomo.service
        is_user: false
      extra:
        edit_cmd: "kitty --detach nvim %s"
        open_dir_cmd: "xdg-open %s"
    '';
  };
}
