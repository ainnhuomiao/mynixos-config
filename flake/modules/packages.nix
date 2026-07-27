{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.self.overlays.default ];
      };
    in
    {
      packages = {
        inherit (pkgs)
          bili_tui
          flake-stats-mcp
          motrix-next
          ;
      };
    };
}
