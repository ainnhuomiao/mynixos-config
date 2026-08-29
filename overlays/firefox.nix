# 固定 firefox-bin 154.0 + zh-CN 语言包 (2026-08-29)。
# 背景: nixpkgs unstable 每次更新都会抬 firefox-bin 版本, 语言包(strict_max
# 钉旧版)随即 appDisabled, UI 回退英文; 而 addons.mozilla.org 在本机代理下
# 不可达, 只能靠 archive.mozilla.org 手动同步。这里把两者都钉死:
# - firefox-bin-unwrapped: overrideAttrs 固定 version + src
# - firefox-bin (wrapFirefox 包装): buildCommand 追加把固定版 zh-CN.xpi 放入
#   distribution/extensions (Firefox 对所有 profile 自动安装, 替代已删除的
#   lib/scripts/firefox-langpack-sync.sh 运行时同步)
# 注意: 包装层没有 postInstall/installPhase 钩子(runCommand buildCommand,
# 且自定义 installPhase 时 setup.sh 的 runHook postInstall 不执行),
# 语言包必须直接拼进 buildCommand。
# 升级 firefox = 改 version + 两个 sha256 (nix store prefetch-file 实取)。
final: prev:

let
  version = "154.0";
  firefoxTar = final.fetchurl {
    url = "https://archive.mozilla.org/pub/firefox/releases/${version}/linux-x86_64/en-US/firefox-${version}.tar.xz";
    sha256 = "sha256-dmXNSasTQXJwdIMlg45WUTatvHbUG712+yTRWgzHeSs=";
  };
  langpack = final.fetchurl {
    url = "https://archive.mozilla.org/pub/firefox/releases/${version}/linux-x86_64/xpi/zh-CN.xpi";
    sha256 = "sha256-65YN0JkRzkP5AIx6B+7RNYP2Ni3sqCw6pmzSIdJGkiI=";
  };
in
{
  firefox-bin-unwrapped = prev.firefox-bin-unwrapped.overrideAttrs (old: {
    inherit version;
    src = firefoxTar;
  });

  firefox-bin = prev.firefox-bin.overrideAttrs (old: {
    # 语言包随包分发; 文件名必须等于扩展 ID
    buildCommand = old.buildCommand + ''
      mkdir -p "$out/lib/firefox-bin-${version}/distribution/extensions"
      cp ${langpack} "$out/lib/firefox-bin-${version}/distribution/extensions/langpack-zh-CN@firefox.mozilla.org.xpi"
    '';
  });
}
