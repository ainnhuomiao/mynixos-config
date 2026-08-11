{
  pkgs,
  ...
}:
{
  # === 雷电显卡坞:外接 RTX 3050 (GA107),Sway 下 PRIME offload ===
  # 用法:坞通电后 `nvidia-egpu steam` 渲染,显示器仍走 iGPU
  services = {
    # Thunderbolt 授权守护进程(雷电显卡坞热插拔必需)
    hardware.bolt.enable = true;
  };

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];
  hardware.nvidia = {
    modesetting.enable = true; # Wayland 必需(nvidia-drm.modeset=1)
    open = true; # Ampere,open 内核模块
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
    # 游戏用完整 offload wrapper:GL/GLX 走 PRIME 变量,EGL 切回 nvidia vendor,
    # Vulkan 用 Mesa device-select layer 强制选卡(595.84 的 VK_LAYER_NV_optimus 已不过滤设备);
    # 启动前自动检查/加载驱动,就绪后才启动游戏
    (pkgs.writeShellScriptBin "nvidia-egpu" ''
      set -euo pipefail
      export PATH="$PATH:/run/current-system/sw/bin"
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
      else
        echo "未检测到可用的 RTX 3050:请确认坞电源已开启且已授权(boltctl list);" >&2
        echo "若坞已通电,多半是 GPU 楔死(可查 journalctl -k | grep NVRM),请关坞电源 10 秒再开" >&2
        exit 1
      fi
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
      export MESA_VK_DEVICE_SELECT=10de:2584
      export MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=true
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
      if sudo modprobe -r nvidia_drm nvidia_modeset nvidia 2>/dev/null; then
        echo "NVIDIA 驱动已卸载,现在可以安全关闭坞电源"
        notify-send "eGPU 已卸载" "驱动已卸载,可安全关闭坞电源" 2>/dev/null || true
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
