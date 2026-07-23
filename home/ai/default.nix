{
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  mcps = with pkgs; [
    flake-stats-mcp
    mcp-nixos
  ];
in
{
  imports = [ ./mcp.nix ];

  systemd.user.services.cc-switch-cli = {
    Unit = {
      Description = "CC Switch CLI Codex proxy";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.cc-switch-cli}/bin/cc-switch-cli proxy serve --takeover codex";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages =
    with pkgs;
    [
      github-copilot-cli
      claude-code
      codex
      gemini-cli
      opencode
      cc-switch-cli
      inputs.herdr.packages.${system}.default
    ]
    ++ mcps;
}
