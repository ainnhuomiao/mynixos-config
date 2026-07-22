final: prev:

# nixpkgs 的 motrix-next 从上游拉了预编译的 sidecar 二进制 `motrix-next-engine`
# （来自 github.com/AnInsomniacy/aria2-next 的 Release），但打包时没有 patchelf，
# 因此在 NixOS 上启动 aria2 引擎时会失败：
#   Could not start dynamically linked executable: .../bin/motrix-next-engine
# 这里在 postFixup 之后追加一步，用 autoPatchelfHook 修好 sidecar 的动态链接器与 rpath。

{
  motrix-next = prev.motrix-next.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.autoPatchelfHook ];

    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.stdenv.cc.cc.lib # libgcc_s / libstdc++
      prev.zlib
    ];

    # motrix-next-engine 是通用 linux ELF，需要指向 nixpkgs 的 ld-linux 与 glibc。
    # autoPatchelfHook 会在 fixupPhase 自动扫描 $out 下的 ELF 并修好。
    dontAutoPatchelf = false;
  });
}
