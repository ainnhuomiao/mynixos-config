{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
}:

let
  pname = "orca-ide";
  version = "1.4.177";
  sources = {
    x86_64-linux = {
      url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
      hash = "sha256-fOkBbvmRBa0TT00XSX8oQHFuh7ii52owTge5E0w3KLw=";
    };
    aarch64-linux = {
      url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux-arm64.AppImage";
      hash = "sha256-ONlp6JkUxFfCBiKiyXI5jGwj3DkUg0OZnWH2CY35sSY=";
    };
  };
  src = fetchurl (
    sources.${stdenv.hostPlatform.system}
      or (throw "orca-ide: unsupported system ${stdenv.hostPlatform.system}")
  );
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [ pkgs.procps ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/orca-ide.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=orca-ide %U"
    install -m 444 -D ${appimageContents}/orca-ide.png \
      $out/share/icons/hicolor/512x512/apps/orca-ide.png
    # Wayland 会话（sway/Hyprland）下走原生 Wayland 渲染，避免 XWayland 分数缩放模糊；
    # X11 会话下 auto 回退 x11。AppRun 的 userns 探测仍生效（不可用时自动 --no-sandbox）
    sed -i '2i export ELECTRON_OZONE_PLATFORM_HINT=auto' $out/bin/orca-ide
    # fcitx5 中文输入：Wayland ozone 默认不启用 text-input 协议，需显式开关；
    # 两个都是 wayland-only 开关，X11 下无副作用。追加在 "$@" 之后，用户显式参数优先
    sed -i 's|container-init "$@"|container-init --enable-wayland-ime=true --enable-features=WaylandWindowDecorations "$@"|' $out/bin/orca-ide
  '';

  meta = {
    description = "ADE for working with a fleet of parallel AI coding agents in isolated git worktrees";
    homepage = "https://onorca.dev/";
    changelog = "https://github.com/stablyai/orca/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
