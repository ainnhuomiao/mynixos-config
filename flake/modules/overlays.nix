{ inputs, ... }:
let
  packages = import ../../pkgs;
in
{
  flake.overlays.default = inputs.nixpkgs.lib.composeManyExtensions (
    [ packages.overlay ] ++ import ../../overlays
  );
}
