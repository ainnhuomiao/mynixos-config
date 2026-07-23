final: prev:

let
  version = "3.9.6";
  src = final.fetchFromGitHub {
    owner = "AnInsomniacy";
    repo = "motrix-next";
    tag = "v${version}";
    hash = "sha256-ynLi+biCdjU7EOq556YuFonghWaxDV7UtHWiKImq7WE=";
  };
in

{
  motrix-next = prev.motrix-next.overrideAttrs (old: {
    inherit version src;

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit version src;
      pname = old.pname;
      cargoRoot = old.cargoRoot;
      hash = "sha256-c17GTD9Wcy9LYLfBcwECNS1Tek5hTWPmie2lXtrbtFc=";
    };

    pnpmDeps = final.fetchPnpmDeps {
      inherit version src;
      pname = old.pname;
      pnpm = final.pnpm_10;
      hash = "sha256-WAuHoLAnFLP6i+rJSegt/hI6sb1SDhm7LWgsup70o9E=";
      fetcherVersion = 3;
    };

    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.autoPatchelfHook ];

    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.stdenv.cc.cc.lib # libgcc_s / libstdc++
      prev.zlib
    ];

    # motrix-next-engine 是通用 linux ELF，需要指向 nixpkgs 的 ld-linux 与 glibc。
    # autoPatchelfHook 会在 fixupPhase 自动扫描 $out 下的 ELF 并修好。
    dontAutoPatchelf = false;

    meta = old.meta // {
      changelog = "https://github.com/AnInsomniacy/motrix-next/releases/tag/v${version}";
    };
  });
}
