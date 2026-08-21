{
  stdenv,
  lib,
  fetchurl,
}:
stdenv.mkDerivation {
  pname = "fcitx5-pinyin-zhwiki";
  version = "20260416";

  src = fetchurl {
    url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.3.0/zhwiki-20260416.dict";
    sha256 = "sha256-m7b9A/A1DMEzQOw0/1n2lb336w8U22rPE8HryR+Jgjs=";
  };

  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/share/fcitx5/pinyin/dictionaries/zhwiki.dict
  '';
  meta = with lib; {
    description = "Fcitx 5 Pinyin Dictionary from zh.wikipedia.org";
    homepage = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki";
    license = licenses.unlicense;
  };
}
