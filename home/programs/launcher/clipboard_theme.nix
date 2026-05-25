{ appearance }:
let
  n = appearance.palettes.nord;
  h = appearance.toHex;
in
''
  configuration {
    font:                       "${appearance.font.name} 12";
    show-icons:                 false;
    disable-history:            false;
    sidebar-mode:               false;
  }

  * {
    bg:  ${h n.nord0};
    fg:  ${h n.nord6};
    ac:  ${h n.nord8};
    al:  ${h n.nord1};
    se:  ${h n.nord2};
  }

  window {
    transparency:               "real";
    background-color:           @bg;
    text-color:                 @fg;
    border:                     2px;
    border-color:               @ac;
    border-radius:              12px;
    width:                      45%;
    location:                   center;
    x-offset:                   0;
    y-offset:                   0;
  }

  prompt {
    enabled:                    true;
    padding:                    0% 1% 0% 0%;
    background-color:           @al;
    text-color:                 ${h n.nord9};
    font:                       "${appearance.font.name} 14";
    vertical-align:             0.5;
  }

  entry {
    background-color:           @al;
    text-color:                 ${h n.nord8};
    placeholder-color:          @bg;
    expand:                     true;
    horizontal-align:           0;
    vertical-align:             0.5;
    placeholder:                "Search Clipboard History...";
    padding:                    0% 0% 0% 0%;
    blink:                      true;
    font:                       "${appearance.font.name} 14";
  }

  inputbar {
    children:                   [ prompt, entry ];
    background-color:           @ac;
    text-color:                 @bg;
    expand:                     false;
    border:                     0% 0% 0% 0%;
    border-radius:              0px;
    border-color:               @ac;
    margin:                     0% 0% 0% 0%;
    padding:                    1.5%;
  }

  listview {
    background-color:           @al;
    padding:                    10px;
    columns:                    1;
    lines:                      15;
    fixed-height:               false;
    scrollbar:                  true;
    spacing:                    4px;
    cycle:                      true;
    dynamic:                    true;
    layout:                     vertical;
  }

  scrollbar {
    handle-width:               8px;
    handle-color:               @ac;
    background-color:           ${h n.nord0};
    border-radius:              4px;
    margin:                     0px 0px 0px 4px;
  }

  mainbox {
    background-color:           @al;
    border:                     0% 0% 0% 0%;
    border-radius:              0% 0% 0% 0%;
    border-color:               @ac;
    children:                   [ inputbar, listview ];
    spacing:                    0%;
    padding:                    0%;
  }

  element {
    background-color:           @al;
    text-color:                 ${h n.nord6};
    orientation:                horizontal;
    border-radius:              4px;
    padding:                    6px 10px 6px 10px;
  }

  element urgent {
    text-color:                 ${h n.nord11};
  }

  element active {
    text-color:                 ${h n.nord13};
  }

  element selected {
    background-color:           @se;
    text-color:                 @fg;
    border:                     0% 0% 0% 0%;
    border-radius:              4px;
    border-color:               @bg;
  }

  element selected.urgent {
    background-color:           @se;
    text-color:                 ${h n.nord11};
  }

  element selected.active {
    background-color:           @se;
    text-color:                 ${h n.nord13};
  }

  element-text {
    background-color:           @al;
    text-color:                 inherit;
    expand:                     true;
    horizontal-align:           0;
    vertical-align:             0.5;
    margin:                     0% 0.25% 0% 0.25%;
    tab-stops:                  [ 45px ];
  }
''
