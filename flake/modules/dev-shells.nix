{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
      };

      devShells = {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            git
            jq
            just
            neovim
            nix-output-monitor
            sbctl
          ];
          inputsFrom = [ config.flake-root.devShell ];
        };

        secret = pkgs.mkShell {
          name = "secret";
          nativeBuildInputs = with pkgs; [
            age
            neovim
            sops
            ssh-to-age
          ];
          shellHook = ''
            export EDITOR=nvim
            export PS1="\[\e[0;31m\](Secret)\$ \[\e[m\]"
          '';
          inputsFrom = [ config.flake-root.devShell ];
        };
      };
    };
}
