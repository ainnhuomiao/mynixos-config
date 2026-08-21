{
  stdenv,
  lib,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "fcitx5-pinyin-moegirl";
  version = "20260812";

  src = fetchurl {
    url = "https://github.com/outloudvi/mw2fcitx/releases/download/20260812/moegirl.dict";
    sha256 = "sha256-JN3PJAS2x2Fsvx2iQZ+K0MYOR4esHGHOsTVl+6dZZVE=";
  };

  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/share/fcitx5/pinyin/dictionaries/moegirl.dict
  '';
  meta = with lib; {
    description = "Fcitx 5 PinyinDictionary from zh.moegirl.org.cn ";
    homepage = "https://github.com/outloudvi/mw2fcitx";
    license = licenses.unlicense;
  };
}
