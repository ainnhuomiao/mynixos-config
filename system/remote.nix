{
  # === 外出远控:Sunshine + Moonlight + Tailscale ===
  # iPad 外出串流打游戏:Sunshine(服务端)→ Moonlight(iPad)→ Tailscale(组网)
  # 使用步骤见 README「外出远控」章节;dae 对 tailscaled 的直连规则在 system/dae.dae
  services = {
    # Sunshine:Moonlight 串流服务端
    # KMS 抓屏需要 CAP_SYS_ADMIN;openFirewall 开 47984-48010 供 Tailscale/局域网访问
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    # Tailscale 组网:Moonlight 走 tailscale0 回连,登录 `sudo tailscale up`
    tailscale.enable = true;

    # 合盖不睡眠/不挂起,保持 Sway 与 KMS 画面可用
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };
}
