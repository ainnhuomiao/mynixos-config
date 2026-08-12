{
  pkgs,
  ...
}:
let
  # 防 eGPU 掉线(Xid 79):把 PCIe 链路设备钉在 D0(禁 D3hot/ASPM L1)。
  # 注意:不能用内核参数 pcie_aspm=off/pcie_port_pm=off —— 实测会阻止 GPU 初始化
  # (设备配置空间全 FF),只能在运行时设置。
  egpu-pm-on = pkgs.writeShellScript "egpu-pm-on" ''
    # 将 $1(DEVPATH,如 /devices/pci0000:00/.../0000:04:00.0)及其所有父级桥
    # 的 runtime PM 设为 on,并禁用 ASPM 省电。
    # 坑:设备枚举瞬间 sysfs 可能还没就绪,写入会失败 —— 必须重试到成功,
    # 否则桥保持 auto 会进 D3hot,唤醒失败就 Xid 79 掉线(实测崩溃)
    d="$1"
    for _ in 1 2 3 4 5; do
      ok=1
      p="$d"
      while [ -n "$p" ] && [ "$p" != "/devices" ] && [ "$p" != "/" ]; do
        echo on >"/sys$p/power/control" 2>/dev/null || ok=0
        p="''${p%/*}"
      done
      [ "$ok" -eq 1 ] && break
      sleep 1
    done
    echo performance >/sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
  '';
in
{
  # === 雷电显卡坞:外接 RTX 3050 (GA107),Sway 下 PRIME offload ===
  # 用法:游戏入口直接交给 `nvidia-egpu`(Steam 启动选项 / HMCL Java 路径 / 手动),
  # 自动检测:GPU 健康→offload 渲染;不可用→回退核显,显示器仍走 iGPU
  services = {
    # Thunderbolt 授权守护进程(雷电显卡坞热插拔必需)
    hardware.bolt.enable = true;

    # 拔插坞/GPU 重新枚举时,自动把新设备及其父桥钉在 D0(防 D3hot 唤醒失败掉线)
    udev.extraRules = ''
      # GPU 出现时钉住整条父链;桥/根端口单独匹配,覆盖 GPU 未枚举的窗口期
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x2584", RUN+="${egpu-pm-on} $env{DEVPATH}"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15d3", RUN+="${egpu-pm-on} $env{DEVPATH}"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa76e", RUN+="${egpu-pm-on} $env{DEVPATH}"
      ACTION=="add", SUBSYSTEM=="thunderbolt", KERNEL=="domain*", RUN+="${egpu-pm-on} /devices"
    '';
  };

  # 启动后兜底:ASPM 设 performance,TB 链路设备 power/control=on
  systemd.services.egpu-power-fix = {
    description = "Pin Thunderbolt eGPU chain to D0 (prevent Xid 79 disconnects)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        (pkgs.writeShellScript "egpu-power-fix" ''
          set -e
          ${egpu-pm-on} /devices
          for d in 0000:00:07.0 0000:03:01.0 0000:03:04.0 0000:04:00.0 0000:04:00.1; do
            echo on >"/sys/bus/pci/devices/$d/power/control" 2>/dev/null || true
          done
          echo on >/sys/bus/thunderbolt/devices/domain0/power/control 2>/dev/null || true
        '')
      ];
    };
  };

  # 轮询兜底:设备枚举时序不可控(udev add 时 sysfs 可能未就绪),
  # 每 30 秒重钉一次,保证任何时序下链路设备都被钉在 D0
  systemd.timers.egpu-power-fix = {
    description = "Periodically re-pin Thunderbolt eGPU chain to D0";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "30s";
      AccuracySec = "1s";
    };
  };

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];
  hardware.nvidia = {
    modesetting.enable = true; # Wayland 必需(nvidia-drm.modeset=1)
    # closed 内核模块:eGPU 上 open 模块 + GSP 固件有已知不稳定
    # (TLB invalidation failed / GSP RPC failed 崩溃,日志实证两次),closed 不依赖 GSP 更稳
    open = false;
    prime = {
      # Sway 下 offload.enable 仅生成惰性 X11 配置(bus ID 不会被读取),
      # 保留是因为 enableOffloadCmd 断言依赖它
      offload.enable = true;
      offload.enableOffloadCmd = true; # 提供 nvidia-offload 命令
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:4@0:0:0";
    };
  };

  # 全局 EGL 只走 Mesa:合成器/桌面程序不占住 nvidia 模块,
  # 才能支持"关坞电源前 modprobe -r"的安全热拔(ArchWiki 方案)
  environment.sessionVariables.__EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";

  environment.systemPackages = with pkgs; [
    # 自动 eGPU 启动器:包住游戏进程,GPU 健康 → 带完整 PRIME offload 环境;
    # GPU 不可用(未通电/楔死)→ 清掉 nvidia 环境变量回退核显,游戏照常能跑。
    # 接入口:Steam 启动选项 `nvidia-egpu %command%`、HMCL 的 Java 路径指向本脚本、或手动敲
    (pkgs.writeShellScriptBin "nvidia-egpu" ''
      # 用法:nvidia-egpu <command...>
      set -euo pipefail
      export PATH="$PATH:/run/current-system/sw/bin"
      [ $# -gt 0 ] || { echo "usage: nvidia-egpu <command...>" >&2; exit 1; }
      # 坑:nvidia-smi -L 在 GPU 楔死(驱动 full-chip reset 后)时仍 exit 0、只打印
      # "No devices found.",所以必须检查输出以 "GPU " 开头,否则会在坏 GPU 上照常启动游戏
      if ! nvidia-smi -L 2>/dev/null | grep -q '^GPU '; then
        echo "NVIDIA 驱动未加载,尝试加载..."
        sudo modprobe nvidia_drm || true
        for _ in 1 2 3 4 5; do
          nvidia-smi -L 2>/dev/null | grep -q '^GPU ' && break
          sleep 1
        done
      fi
      if nvidia-smi -L 2>/dev/null | grep -q '^GPU '; then
        nvidia-smi -L
        notify-send "eGPU 已就绪" "$(nvidia-smi -L | head -1)" 2>/dev/null || true
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
        export MESA_VK_DEVICE_SELECT=10de:2584
        export MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=true
      else
        # eGPU 不可用:必须清掉 nvidia 环境变量再跑,否则游戏会像坏 GPU 时一样建不了 GL 上下文
        echo "eGPU 不可用($(nvidia-smi -L 2>&1 | head -1)),回退核显渲染: $*" >&2
        notify-send "eGPU 不可用" "回退核显渲染" 2>/dev/null || true
        unset __NV_PRIME_RENDER_OFFLOAD __NV_PRIME_RENDER_OFFLOAD_PROVIDER __GLX_VENDOR_LIBRARY_NAME
        unset __EGL_VENDOR_LIBRARY_FILENAMES MESA_VK_DEVICE_SELECT MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE
      fi
      exec "$@"
    '')
    # 卸载驱动并验证:成功才提示可安全关闭坞电源
    (pkgs.writeShellScriptBin "nvidia-egpu-off" ''
      set -euo pipefail
      export PATH="$PATH:/run/current-system/sw/bin"
      if ! grep -q '^nvidia ' /proc/modules; then
        echo "NVIDIA 驱动未加载,无需卸载,可直接关闭坞电源"
        exit 0
      fi
      # GPU 掉线(Xid 79)后 rmmod 会挂起等待 GPU 响应,必须用 timeout 兜底
      if timeout 30 sudo modprobe -r nvidia_drm nvidia_modeset nvidia 2>/dev/null; then
        echo "NVIDIA 驱动已卸载,现在可以安全关闭坞电源"
        notify-send "eGPU 已卸载" "驱动已卸载,可安全关闭坞电源" 2>/dev/null || true
      elif [ $? -eq 124 ]; then
        echo "驱动卸载超时(GPU 已从总线掉线):不要反复重试,直接关坞电源等 10 秒再开" >&2
        exit 1
      else
        echo "卸载失败:有程序仍在使用 GPU(通常是游戏未退出)" >&2
        echo "--- 显存占用进程:" >&2
        nvidia-smi --query-compute-apps=pid,process_name,used_gpu_memory --format=csv 2>/dev/null | tail -n +2 || true
        echo "--- 打开 GPU 设备节点的进程:" >&2
        for p in /proc/[0-9]*; do
          for fd in "$p"/fd/*; do
            case "$(readlink "$fd" 2>/dev/null)" in
              /dev/dri/card1 | /dev/dri/renderD129) echo "$(basename "$p") $(cat "$p"/comm 2>/dev/null)" ;;
            esac
          done
        done | sort -u || true
        echo "退出上述程序后重新执行 nvidia-egpu-off" >&2
        exit 1
      fi
    '')
  ];
}
