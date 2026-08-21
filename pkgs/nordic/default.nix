{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  jdupes,
}:

# 上游 nixpkgs 因依赖被移除的 gtk-engine-murrine 而删除了 nordic，这里自行打包。
# 简化：只装 GTK 主题与壁纸，去掉 GTK2（需 murrine）与 KDE/SDDM 部分。
stdenvNoCC.mkDerivation {
  pname = "nordic";
  version = "2.2.0-unstable-2026-07-23";

  srcs = [
    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic";
      rev = "be5bda37ba01139650e34238336e58e065d2f406";
      hash = "sha256-dQ9xc1kXqc4phCObAwWwHH//vm6NK6z61ieYV3NWWQE=";
      name = "Nordic";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic";
      rev = "be5bda37ba01139650e34238336e58e065d2f406";
      hash = "sha256-dQ9xc1kXqc4phCObAwWwHH//vm6NK6z61ieYV3NWWQE=";
      name = "Nordic-standard-buttons";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic";
      rev = "be5bda37ba01139650e34238336e58e065d2f406";
      hash = "sha256-dQ9xc1kXqc4phCObAwWwHH//vm6NK6z61ieYV3NWWQE=";
      name = "Nordic-darker";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic";
      rev = "be5bda37ba01139650e34238336e58e065d2f406";
      hash = "sha256-dQ9xc1kXqc4phCObAwWwHH//vm6NK6z61ieYV3NWWQE=";
      name = "Nordic-darker-standard-buttons";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic";
      rev = "be5bda37ba01139650e34238336e58e065d2f406";
      hash = "sha256-dQ9xc1kXqc4phCObAwWwHH//vm6NK6z61ieYV3NWWQE=";
      name = "Nordic-bluish-accent";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic";
      rev = "be5bda37ba01139650e34238336e58e065d2f406";
      hash = "sha256-dQ9xc1kXqc4phCObAwWwHH//vm6NK6z61ieYV3NWWQE=";
      name = "Nordic-bluish-accent-standard-buttons";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic-polar";
      rev = "4103a3d4e3445e71de6544b348a3562fa2021ead";
      hash = "sha256-fjTc/KiDdfdbcSw3CRuL61tsdvf1jCae5wr2prA29fA=";
      name = "Nordic-Polar";
    })

    (fetchFromGitHub {
      owner = "EliverLara";
      repo = "nordic-polar";
      rev = "4103a3d4e3445e71de6544b348a3562fa2021ead";
      hash = "sha256-fjTc/KiDdfdbcSw3CRuL61tsdvf1jCae5wr2prA29fA=";
      name = "Nordic-Polar-standard-buttons";
    })
  ];

  sourceRoot = ".";

  nativeBuildInputs = [ jdupes ];

  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    # install theme files
    mkdir -p $out/share/themes
    cp -a Nordic* $out/share/themes

    # remove unneeded files
    rm -r $out/share/themes/*/.gitignore
    rm -r $out/share/themes/*/Art
    rm -r $out/share/themes/*/FUNDING.yml
    rm -r $out/share/themes/*/LICENSE
    rm -r $out/share/themes/*/README.md
    rm -r $out/share/themes/*/{package.json,package-lock.json,Gulpfile.js}
    rm -r $out/share/themes/*/src
    rm -r $out/share/themes/*/cinnamon/*.scss
    rm -r $out/share/themes/*/gnome-shell/{earlier-versions,extensions,*.scss}

    # wallpapers
    mkdir -p $out/share/wallpapers/Nordic/
    mv -v $out/share/themes/Nordic/extras/wallpapers/* $out/share/wallpapers/Nordic/
    rmdir $out/share/themes/Nordic/extras{/wallpapers,}

    # drop GTK2 themes (need gtk-engine-murrine, removed from nixpkgs) and KDE parts
    rm -rf $out/share/themes/*/gtk-2.0
    rm -rf $out/share/themes/*/kde

    # Replace duplicate files with symbolic links to the first file in
    # each set of duplicates, reducing the installed size in about 53%
    jdupes --quiet --link-soft --recurse $out/share

    # FIXME: https://github.com/EliverLara/Nordic/issues/331
    echo "Removing broken symlinks ..."
    find $out -xtype l -print -delete

    runHook postInstall
  '';

  meta = {
    description = "Gtk and KDE themes using the Nord color pallete";
    homepage = "https://github.com/EliverLara/Nordic";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
