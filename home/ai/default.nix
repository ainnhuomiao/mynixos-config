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
  imports = [
    ./mcp.nix
    inputs.nix-pi.homeManagerModules.default
  ];

  home.packages =
    with pkgs;
    [
      github-copilot-cli
      claude-code
      codex
      gemini-cli
      opencode
      cc-switch
      inputs.herdr.packages.${system}.default
    ]
    ++ mcps;
}
