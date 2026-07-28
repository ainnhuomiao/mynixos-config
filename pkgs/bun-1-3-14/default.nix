{
  lib,
  stdenv,
  fetchurl,
  unzip,
  proot,
  runtimeShell,
}:

stdenv.mkDerivation {
  pname = "bun";
  version = "1.3.14";

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-x64.zip";
    hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
  };

  strictDeps = true;
  nativeBuildInputs = [ unzip ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ./bun "$out/libexec/bun"
    mkdir -p "$out/bin"

    # Bun's compiler copies process.execPath into standalone executables. Keep
    # the official Bun ELF untouched and use PRoot only to provide its expected
    # FHS interpreter path while it runs in a Nix sandbox.
    cat >"$out/bin/bun" <<SH
    #!${runtimeShell}
    exec ${proot}/bin/proot \
      -b ${stdenv.cc.bintools.dynamicLinker}:/lib64/ld-linux-x86-64.so.2! \
      "$out/libexec/bun" "\$@"
    SH
    chmod +x "$out/bin/bun"
    ln -s bun "$out/bin/bunx"

    runHook postInstall
  '';

  # Rewriting the raw Bun ELF makes binaries produced by `bun build --compile`
  # invalid, so deliberately skip all generic fixups.
  dontFixup = true;

  meta = {
    description = "Bun JavaScript runtime pinned for building Oh My Pi";
    homepage = "https://bun.sh";
    license = with lib.licenses; [
      mit
      lgpl21Only
    ];
    mainProgram = "bun";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
