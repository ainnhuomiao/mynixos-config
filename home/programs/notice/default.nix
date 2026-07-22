{ appearance, ... }:
let
  n = appearance.palettes.nord;
  h = appearance.toHex;
in
{
  services.mako = {
    enable = true;
    settings = {
      font = "${appearance.font.name} ${toString appearance.font.size}";
      width = 256;
      height = 500;
      margin = "10";
      padding = "5";
      border-size = 3;
      border-radius = 3;
      background-color = h n.nord1;
      border-color = h n.nord8;
      progress-color = "over ${h n.nord2}";
      text-color = h n.nord6;
      default-timeout = 5000;
      text-alignment = "center";
      "urgency=high" = {
        border-color = h n.nord11;
      };
    };
  };
}
