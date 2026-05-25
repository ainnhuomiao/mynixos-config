{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations =
    let
      me = import ../me.nix;
      inherit (inputs.nixpkgs.lib) nixosSystem;
      homeImports = import "${self}/home/profiles";
      mod = "${self}/system";
      specialArgs = {
        inherit inputs self me;
        appearance = import ../lib/appearance.nix;
      };
      mkHomeManager = hostName: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = specialArgs;
          users.${me.userName}.imports =
            homeImports."${me.userName}@${hostName}"
              or (throw "no home profile for ${me.userName}@${hostName}");
        };
      };
    in
    {
      nixos = nixosSystem {
        specialArgs = specialArgs // {
          enableLanzaboote = false;
        };
        modules = [
          ./nixos
          "${mod}/core"
          "${mod}/core/boot.nix"
          "${mod}/core/network.nix"
          "${mod}/nix"
          "${mod}/hardware"
          "${mod}/programs/fonts.nix"
          "${mod}/programs/desktop.nix"
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.home-manager.nixosModules.home-manager
          (mkHomeManager "nixos")
        ];
      };
    };
}
