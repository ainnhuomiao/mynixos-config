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
    # Vulkan 用 Mesa device-select layer 强制选卡(595.84 的 VK_LAYER_NV_optimus 已不过滤设备)
    (pkgs.writeShellScriptBin "nvidia-egpu" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
      export MESA_VK_DEVICE_SELECT=10de:2584
      export MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=true
      exec "$@"
    '')
  ];
}
