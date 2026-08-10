{
  # caelestia-shell 中文汉化包装: 对 flake input 的 with-cli 包应用
  # patches/caelestia-zh_CN.patch (hdcy/Caelestia_Shell_zh_CN 字典生成的统一 diff)。
  # 用法: import ../lib/caelestia-zh.nix { inherit inputs system; }
  # 重新生成 patch: 见 ~/hanhua_drive.py (生成补丁模式)
  inputs,
  system,
}:
let
  shell = inputs.caelestia-shell.packages.${system}.with-cli;
in
shell.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ../patches/caelestia-zh_CN.patch.gz ];
})
