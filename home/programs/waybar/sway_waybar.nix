{
  pkgs,
  appearance,
  lib,
  ...
}:
let
  sharedScripts = import ./share_scripts.nix { inherit pkgs; };
  cp = appearance.catppuccin.${appearance.catppuccinVariant};
  h = appearance.toHex;
in
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "sway-session.target" ];
    };
    style = ''
      /* catppuccin ${appearance.catppuccinVariant} (固定主题, 切换: lib/appearance.nix 的 catppuccinVariant) */
      @define-color wall_bg     ${h cp.bg};
      @define-color wall_bg_alt ${h cp.color0};
      @define-color wall_fg     ${h cp.fg};
      @define-color wall_fg_dim ${h cp.color7};
      @define-color wall_red    ${h cp.color1};
      @define-color wall_green  ${h cp.color2};
      @define-color wall_yellow ${h cp.color3};
      @define-color wall_blue   ${h cp.color4};
      @define-color wall_purple ${h cp.color5};
      @define-color wall_cyan   ${h cp.color6};

      * {
        font-family: "${appearance.font.name}";
        font-size: 12pt;
        font-weight: bold;
        color: @wall_fg;
        border-radius: 0px;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      @keyframes blink_red {
        to {
          background-color: @wall_red;
          color: @wall_bg;
        }
      }

      .warning,
      .critical,
      .urgent {
        animation-name: blink_red;
        animation-duration: 1s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      window#waybar {
        background-color: transparent;
      }

      window>box {
        margin-left: 5px;
        margin-right: 5px;
        margin-top: 5px;
        background-color: @wall_bg_alt;
      }

      #workspaces {
        padding-left: 0px;
        padding-right: 4px;
      }

      #workspaces button {
        padding-top: 5px;
        padding-bottom: 5px;
        padding-left: 6px;
        padding-right: 6px;
        color: @wall_fg_dim;
      }

      #workspaces button label {
        color: inherit;
      }

      #workspaces button.focused {
        background-color: @wall_cyan;
        color: @wall_bg;
      }

      #workspaces button.focused label,
      #workspaces button.urgent label,
      #workspaces button:hover label {
        color: @wall_bg;
      }

      #workspaces button.urgent {
        color: @wall_bg;
      }

      #workspaces button:hover {
        background-color: @wall_purple;
        color: @wall_bg;
      }

      tooltip {
        /* background: rgb(250, 244, 252); */
        background: @wall_bg_alt;
      }

      tooltip label {
        color: @wall_fg;
      }

      #custom-launcher {
        font-size: 20px;
        padding-left: 8px;
        padding-right: 6px;
        color: @wall_blue;
      }

      #mode,
      #clock,
      #memory,
      #temperature,
      #cpu,
      #mpd,
      #custom-wall,
      #temperature,
      #backlight,
      #pulseaudio,
      #network,
      #battery,
      #custom-powermenu,
      #custom-cava-internal {
        padding-left: 10px;
        padding-right: 10px;
      }

      /* #mode { */
      /* 	margin-left: 10px; */
      /* 	background-color: rgb(248, 189, 150); */
      /*     color: rgb(26, 24, 38); */
      /* } */
      #memory {
        color: @wall_cyan;
      }

      #cpu {
        color: @wall_purple;
      }

      #clock {
        color: @wall_fg;
      }

      #custom-wall {
        color: @wall_purple;
      }

      #custom-recgif {
        color: @wall_fg;
      }

      #temperature {
        color: @wall_blue;
      }

      #backlight {
        color: @wall_green;
      }

      #pulseaudio {
        color: @wall_yellow;
      }

      #network {
        color: @wall_green;
      }

      #network.disconnected {
        color: @wall_fg_dim;
      }

      #battery.charging,
      #battery.full,
      #battery.discharging {
        color: @wall_yellow;
      }

      #battery.critical:not(.charging) {
        color: @wall_fg_dim;
      }

      #custom-powermenu {
        color: @wall_red;
      }

      #tray {
        padding-right: 8px;
        padding-left: 10px;
      }

      #tray menu {
        background: @wall_bg_alt;
        color: @wall_fg_dim;
      }

      #mpd.paused {
        color: @wall_blue;
        font-style: italic;
      }

      #mpd.stopped {
        background: transparent;
      }

      #mpd {
        color: @wall_fg;

        /* color: #c0caf5; */
      }

      #custom-cava-internal {
        font-family: "${appearance.font.name}";
      }
    '';
    settings = [
      {
        mode = "dock";
        start_hidden = false;
        modules-left = [
          "custom/launcher"
          "sway/workspaces"
          "temperature"
          "custom/wall"
          "mpd"
          "custom/cava-internal"
          "custom/recgif"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "pulseaudio"
          "backlight"
          "memory"
          "cpu"
          # "network"
          "battery"
          "custom/powermenu"
          "tray"
        ];
        "custom/launcher" = {
          "format" = " ";
          "on-click" = "~/.config/rofi/launcher.sh";
          "tooltip" = false;
        };
        "custom/recgif" = {
          "format" = "{icon}";
          "return-type" = "json";
          "format-icons" = {
            "recording" = "<span foreground='${h cp.color1}'> </span>";
            "stopped" = " ";
          };
          "exec" =
            "pgrep -x recgif >/dev/null && echo '{\"alt\": \"recording\"}' || echo '{\"alt\": \"stopped\"}'";
          "interval" = 1;
          "exec-if" = "sleep 0.1";
          "on-click" = "pkill -SIGINT wf-recorder || ${sharedScripts.recgif}/bin/recgif";
          "on-click-right" = "flameshot gui";
          "tooltip" = false;
        };
        "custom/wall" = {
          "on-click" = "${sharedScripts.wallpaper_random}/bin/wallpaper_random";
          "on-click-middle" = "${sharedScripts.default_wall}/bin/default_wall";
          "on-click-right" = "${sharedScripts.video_wallpaper}/bin/video_wallpaper";
          "format" = " 󰠖 ";
          "tooltip" = false;
        };
        "custom/cava-internal" = {
          "exec" = "sleep 1s && ${sharedScripts.cava-internal}/bin/cava-internal";
          "tooltip" = false;
        };
        "sway/workspaces" = {
          "disable-scroll" = true;
        };
        "backlight" = {
          "on-scroll-up" = "brightnessctl set +5%";
          "on-scroll-down" = "brightnessctl set 5%-";
          "format" = "{icon} {percent}%";
          "format-icons" = [
            "󰃝"
            "󰃞"
            "󰃟"
            "󰃠"
          ];
        };
        "pulseaudio" = {
          "scroll-step" = 1;
          "format" = "{icon} {volume}%";
          "format-muted" = "󰖁 Muted";
          "format-icons" = {
            "default" = [
              ""
              ""
              ""
            ];
          };
          "on-click" = "pamixer -t";
          "tooltip" = false;
        };
        "battery" = {
          "interval" = 10;
          "states" = {
            "warning" = 20;
            "critical" = 10;
          };
          "format" = "{icon} {capacity}%";
          "format-icons" = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          "format-full" = "{icon} {capacity}%";
          "format-charging" = "󰂄 {capacity}%";
          "tooltip" = false;
        };
        "clock" = {
          "interval" = 1;
          "format" = "{:%I:%M %p  %A %b %d}";
          "tooltip" = true;
          "tooltip-format" = "<tt>{calendar}</tt>";
          "calendar" = {
            "mode" = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "format" = {
              "months" = "<span color='${h cp.color3}'><b>{}</b></span>";
              "days" = "<span color='${h cp.color5}'><b>{}</b></span>";
              "weeks" = "<span color='${h cp.color6}'><b>W{}</b></span>";
              "weekdays" = "<span color='${h cp.color3}'><b>{}</b></span>";
              "today" = "<span color='${h cp.color1}'><b><u>{}</u></b></span>";
            };
          };
          "actions" = {
            "on-click-right" = "mode";
            "on-scroll-up" = "shift_up";
            "on-scroll-down" = "shift_down";
          };
        };
        "memory" = {
          "interval" = 1;
          "format" = "󰍛 {percentage}%";
          "states" = {
            "warning" = 85;
          };
        };
        "cpu" = {
          "interval" = 1;
          "format" = "󰻠 {usage}%";
        };
        "mpd" = {
          "max-length" = 25;
          "format" = "<span foreground='${h cp.color5}'></span> {title}";
          "format-paused" = " {title}";
          "format-stopped" = "<span foreground='${h cp.color5}'></span>";
          "format-disconnected" = "";
          "on-click" = "mpc --quiet toggle";
          "on-click-right" = "mpc update; mpc ls | mpc add";
          "on-click-middle" = "kitty --class='ncmpcpp' ncmpcpp";
          "on-scroll-up" = "mpc --quiet prev";
          "on-scroll-down" = "mpc --quiet next";
          "smooth-scrolling-threshold" = 5;
          "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
        };
        "network" = {
          "interval" = 1;
          "format-wifi" = "󰖩 {essid} ({ipaddr})";
          "format-ethernet" = "󰀂 {ifname} ({ipaddr})";
          "format-linked" = "󰖪 {essid} (No IP)";
          "format-disconnected" = "󰯡 Disconnected";
          "tooltip" = false;
        };
        "temperature" = {
          #"critical-threshold"= 80;
          "tooltip" = false;
          "format" = " {temperatureC}°C";
        };
        "custom/powermenu" = {
          "format" = "";
          "on-click" = "~/.config/rofi/powermenu.sh";
          "tooltip" = false;
        };
        "tray" = {
          "icon-size" = 15;
          "spacing" = 5;
        };
      }
    ];
  };

  systemd.user.services.waybar = {
    Unit = {
      Wants = [ "pipewire-pulse.service" ];
      After = [
        "pipewire-pulse.service"
        # 视频壁纸先起:登录/激活时与 mpvpaper 同刻抢 layer-shell 会触发
        # "Timed out waiting for initial .configure", bar 注册后不映射到屏幕
        # (2026-08-20 更新后 waybar 消失事件)。
        "video-wall.service"
      ];
      # hm 模块默认挂 tray.target, 会激活 tray.target 把 waybar 拉进会话。
      # waybar 只属于 sway。
      PartOf = lib.mkForce [ "sway-session.target" ];
    };
    Service = {
      Environment = [ "GDK_BACKEND=wayland" ];
      # 会话启动忙期(合成器加载配置 + 客户端批量连接)后首个 layer configure
      # 可能 >4s 才回复 → waybar 超时后 surface 永不映射。ExecStartPre 等
      # mpvpaper 的 IPC socket 就绪(视频壁纸真正占层)后再起, 错开竞争。
      ExecStartPre = [
        (pkgs.writeShellScript "waybar-wait-mpvpaper" ''
          # systemd user 服务 PATH 不含 coreutils, 必须全路径。
          # 视频壁纸模式下轮询 mpvpaper 的 IPC socket(真正占层)后再起 waybar,
          # 错开登录/激活时 layer-shell configure 竞争。
          # 静态模式 (video-wall 未运行) 立即继续, 不白等。
          if ${pkgs.systemd}/bin/systemctl --user is-active --quiet video-wall.service; then
            for ((i = 0; i < 30; i++)); do
              if [ -S /tmp/mpvpaper.sock ]; then
                exit 0
              fi
              ${pkgs.coreutils}/bin/sleep 0.2
            done
          fi
          # 30*0.2s=6s 未就绪或静态模式: 直接启动, 不阻塞 waybar
          exit 0
        '')
      ];
      RestartSec = 2;
      # hm 模块默认 Restart=on-failure + ConditionEnvironment=WAYLAND_DISPLAY:
      # 会话结束时 waybar 随 wayland 断连崩溃, 而 user manager 里 WAYLAND_DISPLAY
      # 是陈旧的 (dbus-update-activation-environment 残留) → 重启会成功连上
      # 新会话 (2026-08-09 实测 waybar 泄漏驻留 21 分钟)。
      # Restart=no: 会话结束时安静退出, 下次 sway-session.target 启动时全新拉起。
      Restart = lib.mkForce "no";
    };
    Install.WantedBy = lib.mkForce [ "sway-session.target" ];
  };
}
