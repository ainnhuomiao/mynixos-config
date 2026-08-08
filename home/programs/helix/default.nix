{ pkgs, ... }:
let
  # Frappé theme from catppuccin/helix (user themes dir wins over helix runtime)
  catppuccinFrappe = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/helix/main/themes/default/catppuccin_frappe.toml";
    sha256 = "sha256-fK+DnpCjO5qj4TGUQiVa0h4SKEbNPI21d/XEi8gI8jI=";
  };
in
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        line-number = "relative";
        mouse = false;
        bufferline = "always";
        color-modes = true;
        true-color = true;
        cursorline = true;
        cursor-shape = {
          insert = "bar";
        };
        indent-guides = {
          render = true;
          character = "▎";
        };
        soft-wrap.enable = true;
        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
          ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
          ];
        };
        whitespace = {
          render.space = "all";
          characters = {
            space = "·";
            nbsp = "⍽";
            tab = "→";
            newline = "↵";
          };
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
      ];
    };
    ignores = [
      ".direnv"
      "result"
    ];
  };

  xdg.configFile."helix/themes/catppuccin_frappe.toml".source = catppuccinFrappe;
}
