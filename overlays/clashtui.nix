final: prev: {
  clashtui = prev.clashtui.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/clashtui-zh-cn.patch
    ];
  });
}
