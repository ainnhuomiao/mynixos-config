{ pkgs, ... }:
let
  wallpaperDirectory = ../../../assets/wallpapers;
  selectWallpaper = ''
    wallpaper=$(${pkgs.findutils}/bin/find "${wallpaperDirectory}" -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
      -print0 | ${pkgs.coreutils}/bin/shuf -z -n 1 | ${pkgs.findutils}/bin/xargs -0 -r printf '%s')
    if [[ -z "$wallpaper" ]]; then
      ${pkgs.libnotify}/bin/notify-send "Wallpaper" "No images found in assets/wallpapers"
      exit 1
    fi
  '';
in
{
  cava-internal = pkgs.writeShellScriptBin "cava-internal" ''
    killall cava
    cava -p ~/.config/cava/config_internal | sed -u 's/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;'
  '';
  wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
    ${pkgs.procps}/bin/pkill -f '/bin/dynamic_wallpaper' || true
    ${selectWallpaper}
    ${pkgs.awww}/bin/awww img "$wallpaper" --transition-type random
  '';
  dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
    while true; do
      ${selectWallpaper}
      ${pkgs.awww}/bin/awww img "$wallpaper" --transition-type random
      ${pkgs.coreutils}/bin/sleep 120
    done
  '';
  default_wall = pkgs.writeShellScriptBin "default_wall" ''
    ${pkgs.procps}/bin/pkill -f '/bin/dynamic_wallpaper' || true
    ${pkgs.awww}/bin/awww img "${wallpaperDirectory}/default.png" --transition-type random
  '';
  recgif = pkgs.writeShellScriptBin "recgif" ''
    TIMESTAMP=$(date "+%Y-%m-%dT%H_%M_%S")
    TEMP_VIDEO="/tmp/recording_$TIMESTAMP.mkv"
    OUTPUT_GIF="$HOME/Pictures/recording_$TIMESTAMP.gif"
    GEOMETRY=$(slurp)
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
    wf-recorder -f "$TEMP_VIDEO" -g "$GEOMETRY"
    if [[ -f "$TEMP_VIDEO" ]]; then
      ffmpeg -i "$TEMP_VIDEO" -vf "fps=15,scale=640:-1:flags=lanczos" -f gif "$OUTPUT_GIF"
      if [[ -f "$OUTPUT_GIF" ]]; then
        notify-send "GIF Conversion Complete" "GIF saved to $OUTPUT_GIF"
      fi
      rm "$TEMP_VIDEO"
    else
      notify-send "Recording Failed" "Video file not found"
    fi
  '';
}
