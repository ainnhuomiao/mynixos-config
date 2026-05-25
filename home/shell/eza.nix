{ appearance, ... }:
let
  t = appearance.palettes.tokyoNight;
  a = appearance.toAnsi;
  mkEzaColors =
    mapping:
    builtins.concatStringsSep ":" (
      builtins.attrValues (builtins.mapAttrs (key: hex: "${key}=${a hex}") mapping)
    );
in
{
  home.sessionVariables.EZA_COLORS = mkEzaColors {
    # file types
    di = t.blue; # directory
    ex = t.teal; # executable
    ln = t.cyan; # symlink
    or = t.red; # broken symlink

    # permissions
    ur = t.yellow;
    uw = t.red;
    ux = t.teal;
    ue = t.teal;
    gr = t.yellow;
    gw = t.red;
    gx = t.teal;
    tr = t.yellow;
    tw = t.red;
    tx = t.teal;

    # metadata
    sn = t.blue; # size number
    sb = t.comment; # size unit
    da = t.comment; # date
    uu = t.blue; # current user
    un = t.comment; # other user
    gu = t.purple; # current group
    gn = t.comment; # other group
  };
}
