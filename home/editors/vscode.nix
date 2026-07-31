{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default = {
      extensions = [
        pkgs.vscode-extensions.catppuccin.catppuccin-vsc
      ];
      userSettings = {
        "workbench.colorTheme" = "Catppuccin Mocha";
        "catppuccin.accentColor" = "mauve";
        "catppuccin.boldKeywords" = true;
        "catppuccin.italicComments" = true;
        "catppuccin.italicKeywords" = true;
        "catppuccin.workbenchMode" = "default";
        "catppuccin.bracketMode" = "rainbow";
        "catppuccin.extraBordersEnabled" = false;
        "editor.semanticHighlighting.enabled" = true;
        "terminal.integrated.minimumContrastRatio" = 1;
        "window.titleBarStyle" = "custom";
      };
    };
  };
}
