{
  pkgs,
  ...
}:
let
  v2rayN = pkgs.v2rayn;

  # 包装 v2rayN：启动时停掉 dae(透明代理)+mihomo，退出(含崩溃/Ctrl+C)后自动恢复。
  # 依赖 system/mihomo.nix 与 system/dae.nix 里的 polkit 规则（免 sudo 管理这两个 unit）。
  # dae `Requires=mihomo.service`：停 mihomo 会连带停 dae，启动 dae 会连带拉起 mihomo；
  # 脚本仍显式按序 stop/start，避免依赖隐式传播。
  wrapper = pkgs.writeShellApplication {
    name = "v2rayN";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
    ];
    text = ''
      V2RAYN_BIN="${v2rayN}/bin/v2rayN"
      FLAG="''${XDG_RUNTIME_DIR:-/tmp}/v2rayN-managed-services"

      # wrapper 被外部信号终止时, 先杀掉后台 v2rayN 子进程再恢复服务,
      # 避免 v2rayN 变孤儿与 dae TUN 同时接管(正常退出时 kill 静默失败)
      CHILD_PID=""

      stop_transparent_proxy() {
        # 先 dae 后 mihomo，避免 Requires 传播顺序产生竞态
        systemctl is-active --quiet dae.service 2>/dev/null && systemctl stop dae.service || true
        systemctl is-active --quiet mihomo.service 2>/dev/null && systemctl stop mihomo.service || true
        touch "$FLAG"
        echo "v2rayN: 已停止 dae + mihomo（透明代理旁路，由 v2rayN 接管）"
      }

      restore_transparent_proxy() {
        if [ -n "$CHILD_PID" ]; then
          kill "$CHILD_PID" 2>/dev/null || true
          wait "$CHILD_PID" 2>/dev/null || true
        fi
        if [ -f "$FLAG" ]; then
          rm -f "$FLAG"
          systemctl start mihomo.service || true
          systemctl start dae.service || true
          sleep 0.3
          systemctl is-active --quiet mihomo.service || \
            echo "v2rayN: 警告 mihomo.service 未运行, 请检查 systemctl status mihomo" >&2
          systemctl is-active --quiet dae.service || \
            echo "v2rayN: 警告 dae.service 未运行, 请检查 systemctl status dae" >&2
          echo "v2rayN: 已退出, 恢复 dae + mihomo（透明代理）"
        fi
      }

      trap restore_transparent_proxy EXIT

      stop_transparent_proxy
      "$V2RAYN_BIN" "$@" &
      CHILD_PID=$!
      wait "$CHILD_PID"
    '';
  };
in
{
  # 只装 wrapper：它与原始包都提供 `bin/v2rayN`，同时放 home.packages 会让 buildEnv
  # 撞名报错；wrapper 内嵌 ${v2rayN}/bin/v2rayN 绝对路径(被 Nix 扫描进闭包)，
  # 真实二进制随 wrapper 一起进入系统/home 闭包。
  # 同名 bin 保证终端输入 v2rayN 与下方 desktop 入口都走切换逻辑。
  home.packages = [
    wrapper
  ];

  # 覆盖 nixpkgs 自带的 v2rayn.desktop(Exec=v2rayN 走 PATH)：显式指向 wrapper 绝对路径
  home.file.".local/share/applications/v2rayn.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=v2rayN
      GenericName=v2rayN
      Comment=Graphical client for Xray / sing-box; stops dae+mihomo on launch and restores them on exit
      Exec=${wrapper}/bin/v2rayN
      Icon=${v2rayN}/share/icons/hicolor/256x256/apps/v2rayn.png
      Categories=Network;
      Terminal=false
      StartupNotify=false
    '';
  };
}
