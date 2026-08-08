{
  appimageTools,
  fetchurl,
  jdk8,
  jdk17,
  jdk21,
  lib,
  wayland,
}:

let
  version = "1.6.11";

  src = fetchurl {
    url = "https://github.com/Mystic-Stars/Axolotl/releases/download/v${version}/Axolotl.Launcher_${version}_amd64.AppImage";
    hash = "sha256-ftjDi2P/TNDl+nt7x/Fx+VjN6mhLgh4fWAZnZORPmuk=";
  };

  appimageContents = appimageTools.extractType2 {
    pname = "axolotl";
    inherit version src;
    postExtract = ''
      # linuxdeploy 的钩子强制 GDK_BACKEND=x11，在 Wayland 下导致 WebKit EGL 初始化失败，移除
      sed -i '/linuxdeploy-plugin-gtk.sh/d' $out/AppRun
      # WebKit 辅助进程按 cwd 相对路径查找（PKGLIBEXECDIR 被 linuxdeploy 重写），
      # AppRun.wrapped 会 chdir 到 APPDIR，故在解包目录内建 lib/... 链接
      mkdir -p $out/lib/x86_64-linux-gnu
      ln -s ../usr/lib/x86_64-linux-gnu/webkit2gtk-4.1 $out/lib/x86_64-linux-gnu/webkit2gtk-4.1
    '';
  };
in

appimageTools.wrapType2 {
  pname = "axolotl";
  inherit version src;

  extraInstallCommands = ''
    # AppImage 内打包的旧 libwayland-client 会遮蔽 FHS 新版，导致 Mesa EGL display 创建失败
    # （eglGetDisplay 返回 EGL_BAD_PARAMETER），强制使用 FHS 内的 libwayland-client
    sed -i 's|^exec "''${cmd\[@\]}"|export LD_PRELOAD=${wayland}/lib/libwayland-client.so.0\nexport GDK_BACKEND=wayland\nexport JAVA_HOME=${jdk21}/lib/openjdk\nexport PATH=${jdk21}/bin:${jdk17}/bin:${jdk8}/bin:''$PATH\nexec "''${cmd[@]}"|' $out/bin/axolotl
    install -Dm444 '${appimageContents}/usr/share/applications/Axolotl Launcher.desktop' $out/share/applications/axolotl.desktop
    substituteInPlace $out/share/applications/axolotl.desktop --replace-fail 'Exec=axolotl-launcher' 'Exec=axolotl'
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/128x128/apps/axolotl-launcher.png $out/share/icons/hicolor/128x128/apps/axolotl-launcher.png
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/256x256@2/apps/axolotl-launcher.png $out/share/icons/hicolor/256x256@2/apps/axolotl-launcher.png
  '';

  meta = {
    description = "Cross-platform Minecraft launcher";
    homepage = "https://github.com/Mystic-Stars/Axolotl";
    license = lib.licenses.gpl3Only;
    mainProgram = "axolotl";
    platforms = [ "x86_64-linux" ];
  };
}
