{
  lib,
  stdenv,
  fetchurl,
  python3,
  patchelf,
  bun_1_3_14,
  bun2nix,
  src,
  patchSrc,
}:

let
  packageJson = lib.importJSON (src + "/package.json");
  patchedDependencies = lib.mapAttrs (_: path: src + "/${path}") (
    packageJson.patchedDependencies or { }
  );
  patchOverrides = bun2nix.patchedDependenciesToOverrides {
    inherit patchedDependencies;
  };
  bunNix = builtins.toFile "oh-my-pi-bun.nix" (
    builtins.replaceStrings [ "__OH_MY_PI_SRC__" ] [ (toString src) ] (builtins.readFile ./bun.nix)
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "oh-my-pi-zh";
  version = "17.1.7";

  inherit src;

  officialOmp = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${finalAttrs.version}/omp-linux-x64";
    hash = "sha256-M74CMt6P/01UIFjWZu4VzxVKZgCSJX1L+z/qi8f59uA=";
  };

  nativeBuildInputs = [
    bun_1_3_14
    python3
    patchelf
  ];

  bunDeps = bun2nix.fetchBunDeps {
    inherit bunNix;
    overrides = patchOverrides;
  };

  postPatch = ''
    cp ${patchSrc}/patch_omp_zh_v2.py ./patch_omp_zh_v2.py
    python3 ./patch_omp_zh_v2.py
    rm ./patch_omp_zh_v2.py

    # PRoot's path emulation does not implicitly create Bun.write's parent
    # directory here, so make the upstream build step explicit.
    substituteInPlace packages/stats/build.ts \
      --replace-fail \
      'await fs.rm("./dist/client", { recursive: true, force: true });' \
      $'await fs.rm("./dist/client", { recursive: true, force: true });\nawait fs.mkdir("./dist/client", { recursive: true });'
  '';

  configurePhase = ''
    runHook preConfigure

    export HOME="$TMPDIR/omp-home"
    export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
    mkdir -p "$HOME" "$BUN_INSTALL_CACHE_DIR"

    # fetchBunDeps provides a complete offline cache. Dereference its store
    # symlinks because Bun may atomically replace entries while installing.
    cp -rL ${finalAttrs.bunDeps}/share/bun-cache/. "$BUN_INSTALL_CACHE_DIR"/
    chmod -R u+w "$BUN_INSTALL_CACHE_DIR"

    # Bun otherwise consults the registry for catalog: dependencies even in
    # offline/frozen mode. Resolve them from the pinned lock file first.
    bun --config=/dev/null --no-install ${./resolve-catalog.ts} .

    # The cache entries were already patched by fetchBunDeps overrides. Remove
    # patchedDependencies so Bun uses those normal cache keys instead of trying
    # to apply the source patches a second time.
    python3 - <<'PY'
    import json
    from pathlib import Path

    for name in ("package.json", "bun.lock"):
        path = Path(name)
        data = json.loads(path.read_text())
        data.pop("patchedDependencies", None)
        path.write_text(json.dumps(data, indent=2) + "\n")
    PY

    bun install \
      --linker=isolated \
      --frozen-lockfile \
      --offline \
      --ignore-scripts

    runHook postConfigure
  '';

  preBuild = ''
    mkdir -p "$HOME" packages/natives/native

    # Starting the release binary once extracts its bundled native addons.
    # --help avoids the subprocess probe used by --smoke-test; the unpatched
    # release binary itself must be invoked through the Nix dynamic linker.
    BUN_SELF_EXE=${finalAttrs.officialOmp} \
      ${stdenv.cc.bintools.dynamicLinker} \
      ${finalAttrs.officialOmp} --help >/dev/null

    cp "$HOME/.omp/natives/${finalAttrs.version}/pi_natives."*.node \
      packages/natives/native/
  '';

  buildPhase = ''
    runHook preBuild

    bun --cwd=packages/coding-agent run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 packages/coding-agent/dist/omp "$out/bin/omp"

    # Patch only the ELF interpreter. This keeps the Bun standalone payload
    # intact while making process.execPath point to omp itself, which is needed
    # when OMP relaunches the executable for worker subprocesses.
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$out/bin/omp"

    runHook postInstall
  '';

  # Generic fixup would run patchelf a second time and corrupt Bun's appended
  # standalone payload. The interpreter was patched explicitly above.
  dontFixup = true;
  dontStrip = true;

  meta = {
    description = "Chinese-localized build of the Oh My Pi coding agent, built from source";
    homepage = "https://github.com/LiuQingHuaYang/oh-my-pi-zh";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
})
