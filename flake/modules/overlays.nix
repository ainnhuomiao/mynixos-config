{ inputs, ... }:
let
  packages = import ../../pkgs { inherit inputs; };
in
{
  flake.overlays.default = inputs.nixpkgs.lib.composeManyExtensions (
    [ packages.overlay ] ++ import ../../overlays
  );
}
