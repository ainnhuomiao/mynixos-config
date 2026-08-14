{
  config,
  lib,
  pkgs,
  inputs,
  me,
  ...
}:
let
  myGoModule =
    with lib;
    let
      cfg = config.programs.go;
    in
    {
      options.programs.go = {
        go111Module = mkOption {
          type = with types; nullOr str;
          default = null;
          example = "on";
          description = "GO111MODULE 环境变量的值(如 \"on\" 或 \"off\")";
        };

        goModCache = mkOption {
          type = with types; nullOr str;
          default = null;
          example = "go/pkg/mod";
          description = "The Go mod cache path";
        };

        withMyGo = mkOption {
          type = types.bool;
          default = true;
        };

        extraPackages = mkOption {
          type = with types; listOf package;
          default = [ ];
          description = "Additional packages to install, such as dependencies for Go programs.";
        };

        enableFishIntegration = mkEnableOption "Fish integration";

        enableBashIntegration = mkEnableOption "Bash integration";
      };

      config = {
        home.sessionVariables = (
          mkMerge [
            (mkIf (cfg.go111Module != null) {
              GO111MODULE = cfg.go111Module;
            })

            (mkIf (cfg.goModCache != null) {
              GOMODCACHE = "${config.home.homeDirectory}/${cfg.goModCache}";
            })

          ]
        );
        programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
          set -gx PATH $GOPATH/bin $PATH
        '';
        programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
          export PATH=$GOPATH/bin:$PATH
        '';
        home.packages = (
          (
            if cfg.withMyGo then
              [
                inputs.mygo.packages.${pkgs.stdenv.hostPlatform.system}.default
              ]
            else
              [ ]
          )
          ++ cfg.extraPackages
        );

      };
    };
in
{
  imports = [ myGoModule ];

  programs.go = {
    enable = true;
    env.GOPATH = "${config.home.homeDirectory}/Codelearning/go";
    goModCache = "Codelearning/go/pkg/mod";
    go111Module = "on";
    withMyGo = false;
    enableFishIntegration = true;
    enableBashIntegration = true;
    extraPackages = with pkgs; [
      graphviz
      # pprof
      protobuf
      protoc-gen-go
      protoc-gen-go-grpc
      grpcurl
    ];
  };
}
