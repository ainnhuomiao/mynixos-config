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
      # linuxdeploy 钩子强制 GDK_BACKEND=x11（Wayland 下 WebKit EGL 初始化失败，详见 skill
      # axolotl-appimage-wayland-egl-fix），但钩子同时负责 GTK 模块路径（GTK_IM_MODULE_FILE/
      # GTK_PATH/GTK_EXE_PREFIX 指向 immodules.cache 与 bundled gtk3 模块），整行删除会导致
      # 捆绑 gtk3 找不到任何 IM 模块（fcitx5 输入失效）。保留钩子，在其后覆盖 GDK_BACKEND
      # 并显式启用 wayland IM 模块（im-wayland default_locales 为空，不会自动选中）
      sed -i 's|^exec "''$this_dir"/AppRun.wrapped|export GDK_BACKEND=wayland\nexport GTK_IM_MODULE=wayland\nexec "$this_dir"/AppRun.wrapped|' $out/AppRun
      # WebKit 辅助进程按 cwd 相对路径查找（PKGLIBEXECDIR 被 linuxdeploy 重写），
      # AppRun.wrapped 会 chdir 到 APPDIR，故在解包目录内建 lib/... 链接
      mkdir -p $out/lib/x86_64-linux-gnu
      ln -s ../usr/lib/x86_64-linux-gnu/webkit2gtk-4.1 $out/lib/x86_64-linux-gnu/webkit2gtk-4.1
    '';
  };
in

appimageTools.wrapAppImage {
  pname = "axolotl";
  inherit version;
  # wrapType2 的运行时 contents 只从 pname/version/src 重新解包，会丢掉 postExtract
  # （AppRun 修复不生效）；改用 wrapAppImage 直接指定我们的解包作为运行时内容
  contents = appimageContents;

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
