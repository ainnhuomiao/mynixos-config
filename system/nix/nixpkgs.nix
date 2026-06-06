{
  self,
  inputs,
  ...
}:
{
  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnsupportedSystem = true;
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-39.8.10"
      ];
    };
    overlays = [
      self.overlays.default
      inputs.rust-overlay.overlays.default
      inputs.nur.overlays.default
    ];
  };
}
