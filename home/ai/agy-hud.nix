{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.agy-hud ];

  # agy owns this file, so only manage the statusLine field and preserve the
  # rest of the user's CLI configuration.
  home.activation.configureAgyHud = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.gemini/antigravity-cli/settings.json"
    settings_dir="$(dirname "$settings")"
    ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"

    if [ -s "$settings" ]; then
      settings_tmp="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/settings.json.XXXXXX")"
      if ! ${pkgs.jq}/bin/jq \
        --arg command "${pkgs.agy-hud}/bin/agy-hud" \
        '.statusLine = { type: "", command: $command, enabled: true }' \
        "$settings" > "$settings_tmp"; then
        ${pkgs.coreutils}/bin/rm -f "$settings_tmp"
        exit 1
      fi
    else
      settings_tmp="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/settings.json.XXXXXX")"
      ${pkgs.jq}/bin/jq -n \
        --arg command "${pkgs.agy-hud}/bin/agy-hud" \
        '{ statusLine: { type: "", command: $command, enabled: true } }' \
        > "$settings_tmp"
    fi

    if [ -e "$settings" ]; then
      ${pkgs.coreutils}/bin/chmod --reference="$settings" "$settings_tmp"
    fi
    ${pkgs.coreutils}/bin/mv "$settings_tmp" "$settings"
  '';
}
