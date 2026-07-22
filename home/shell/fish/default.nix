{
  config,
  pkgs,
  appearance,
  ...
}:
let
  t = appearance.palettes.tokyoNight;
  h = appearance.toHex;
in
{
  programs.fish = {
    enable = true;
    loginShellInit =
      if config.wayland.windowManager.sway.enable then
        ''
          set TTY1 (tty)
          [ "$TTY1" = "/dev/tty1" ] && exec sway
        ''
      else
        "";
    interactiveShellInit = ''
      set fish_greeting ""
      set fish_key_bindings  fish_vi_key_bindings
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source

      # add_newline in starship adds blank line before every prompt including
      # the first one, which looks odd on terminal open. instead, print a blank
      # line after each command via postexec so the first prompt stays clean.
      function postexec_newline --on-event fish_postexec
          echo
      end
    '';
    shellAliases = {
      l = "eza -lah --icons";
      la = "eza -a --icons";
      ll = "eza -l --icons";
      ls = "eza";
      n = "fastfetch";
      top = "btop";
      rs = "sudo nixos-rebuild switch --flake ~/mynixos-config#nixos 2>&1 | nom";
      ru = "nix flake update --flake ~/mynixos-config";
      rd = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
    functions = {
      nf = ''
        set -l file (FZF_DEFAULT_COMMAND='fd' FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'" fzf --height 60% --layout reverse --info inline --border --color 'border:${h t.purple}')
        and nvim $file
      '';
      nv = ''
        if command -q neovide.exe
            neovide.exe --wsl $argv
        else if command -q neovide
            neovide $argv
        else
            nvim $argv
        end
      '';
      f = ''
        FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git' FZF_DEFAULT_OPTS="--color=bg+:${h t.sel_bg},bg:${h t.bg},spinner:${h t.orange},hl:${h t.red}  --color=fg:${h t.fg},header:${h t.red},info:${h t.purple},pointer:${h t.orange}  --color=marker:${h t.orange},fg+:${h t.fg},prompt:${h t.purple},hl+:${h t.red} --preview 'bat --style=numbers --color=always --line-range :500 {}'" fzf --height 60% --layout reverse --info inline --border --color 'border:${h t.purple}'
      '';
      "clang++strict" = ''
        clang++ -std=c++20 -Wall -Werror -Wextra -Wconversion -Wsign-conversion -pedantic-errors -ggdb $argv
      '';
    };
  };
  home.file = {
    ".config/fish/conf.d/tokyo_night.fish".text = import ./tokyo_night.nix { inherit appearance; };
    ".config/fish/functions/xdg-get.fish".text = import ./functions/xdg-get.nix;
    ".config/fish/functions/xdg-set.fish".text = import ./functions/xdg-set.nix;
    ".config/fish/functions/owf.fish".text = import ./functions/owf.nix;
    ".config/fish/functions/cd.fish".text = import ./functions/cd.nix;
  };
}
