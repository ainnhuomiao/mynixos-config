# mynixos-config

个人 NixOS Flake 配置，面向 `x86_64-linux` 物理机 `nixos`。系统使用 Sway、Home Manager、Mihomo TUN、Fish 和一组自定义 overlays。

> 这是与当前硬件、用户名和本地状态绑定的个人配置，不是可直接用于任意机器的通用模板。复用前至少需要检查 `me.nix`、`hosts/nixos/hardware-configuration.nix`、磁盘布局和 Mihomo 配置。

## 当前架构

| 项目     | 当前配置                                                      |
| -------- | ------------------------------------------------------------- |
| Flake    | `flake-parts` + `nixos-unstable-small`                        |
| 主机     | `nixos`                                                       |
| 平台     | `x86_64-linux`                                                |
| 桌面     | Sway + Waybar + Rofi + Mako                                   |
| Shell    | Fish + Starship                                               |
| 用户配置 | Home Manager，`useGlobalPkgs` 和 `useUserPackages` 均启用     |
| 音频     | PipeWire，启用 ALSA、PulseAudio 和 JACK                       |
| 网络代理 | Mihomo 系统服务，TUN 自动路由                                 |
| 引导     | GRUB EFI；Lanzaboote 模块已接入，但当前主机未启用 Secure Boot |
| 文件系统 | 当前主机使用 Btrfs 子卷和独立 EFI 分区                        |

## 主要功能

### 桌面

- Sway Wayland 平铺窗口管理器，`Mod` 键为 `Super`
- Waybar 状态栏、托盘和自定义快捷操作
- Rofi 应用启动器、剪贴板历史和电源菜单
- Flameshot 与 Grimshot 截图，不添加水印或额外后处理
- Swaylock 使用当前屏幕的模糊截图作为锁屏背景
- 15 分钟空闲后尝试挂起；有活跃音频流时避免自动挂起
- Fcitx5 中文输入法，使用左 `Ctrl` + 左 `Shift` 切换
- PipeWire、蓝牙、NetworkManager 托盘和 XDG Portal
- Firefox 保持默认界面，仅启用安装和 Wayland 环境变量
- Vesktop 使用 nixpkgs 官方包，并自动放入 `VT` 工作区
- SPlayer 使用 `Alt` + `Shift` + `s` 启动，并自动放入 `SPlayer` 工作区

### 录屏（wf-recorder）

全屏录制并将视频保存到当前目录：

```bash
wf-recorder -f recording.mkv
```

使用 `slurp` 框选录制区域：

```bash
wf-recorder -g "$(slurp)" -f recording.mkv
```

录制画面的同时录制默认音频设备：

```bash
wf-recorder --audio -f recording.mkv
```

框选区域并同时录音：

```bash
wf-recorder -g "$(slurp)" --audio -f recording.mkv
```

多显示器环境下可先查看输出名称，再录制指定输出：

```bash
wf-recorder -L
wf-recorder -o DP-1 -f recording.mkv
```

录制过程中按 `Ctrl` + `C` 即可停止并保存视频。需要固定帧率时可使用
`-r` 参数，例如 `wf-recorder -r 60 -f recording.mkv`。

### Shell

- Fish 使用 Vi 键位并由 Starship 提供提示符
- Fastfetch 不随终端自动运行；可通过 `n` 别名手动启动

### 开发环境

- Neovim、Helix、Git、Lazygit
- C/C++：GCC、Clang、GDB、CMake、Meson、Ninja、Bear
- Rust：`rust-overlay`
- Go、Haskell、Node.js、TypeScript、Bun
- Protobuf、gRPC、Direnv
- `nixd`、`nixfmt`、`treefmt-nix`

### AI 与 MCP

安装以下 AI CLI：

- Claude Code
- Codex
- Gemini CLI
- GitHub Copilot CLI
- OpenCode
- `cc-switch-cli`
- Herdr

`cc-switch-cli` 以 systemd 用户服务运行 Codex 代理，登录后自动执行
`cc-switch-cli proxy serve --takeover codex`，服务异常退出时自动重启。

Home Manager 激活时会将远程 Context7 MCP 地址 `https://mcp.context7.com/mcp` 合并到以下配置：

| 工具               | 配置文件                           |
| ------------------ | ---------------------------------- |
| Codex              | `~/.codex/config.toml`             |
| Claude Code        | `~/.claude.json`                   |
| OpenCode           | `~/.config/opencode/opencode.json` |
| GitHub Copilot CLI | `~/.copilot/mcp-config.json`       |
| cc-switch 数据库   | `~/.cc-switch/cc-switch.db`        |

激活脚本只更新 Context7 项，不接管各工具的完整配置。如果已有 cc-switch 数据库，它还会同步其中的 Codex Live backup，避免代理恢复旧 MCP 配置。

另外安装：

- `mcp-nixos`：NixOS/Nixpkgs 查询 MCP
- `flake-stats-mcp`：本仓库中的简单 Flake 统计 MCP

检查 OpenCode MCP 状态：

```bash
opencode mcp list
```

检查 Codex 代理服务：

```bash
systemctl --user status cc-switch-cli
```

### Mihomo TUN

`system/mihomo.nix` 将 Mihomo 作为系统服务运行：

- TUN 设备名为 `Mihomo`
- 启用 `auto-route`、`auto-redirect`、DNS 劫持和 fake-ip
- RFC1918 私网及 IPv6 ULA 地址不进入 TUN
- MetaCubeXD Web UI：<http://127.0.0.1:9090/ui>
- 多个订阅使用独立的 Mihomo `proxy-providers`，每 6 小时自动更新
- 节点自动添加订阅名前缀，避免不同订阅出现同名节点
- `mihomo-sub` 提供交互式菜单管理订阅，URL 使用隐藏输入
- systemd 监听订阅文件，修改后自动验证、生成配置并重启 Mihomo

订阅信息保存在：

```text
/var/lib/mihomo-config/subscriptions.yaml
```

运行交互式管理器：

```bash
mihomo-sub
```

菜单支持查看、添加或替换、删除、刷新单个订阅和刷新全部订阅。订阅 URL
保存在本机 `/var/lib/mihomo-config/subscriptions.yaml`，不会进入 Git 或 Nix store。

也可以直接编辑底层文件：

```yaml
subscriptions:
  default:
    url: https://example.com/subscription-a
  kitty:
    url: https://example.com/subscription-b
  sanmao-200:
    url: https://example.com/subscription-c
```

添加订阅时增加一个映射，删除订阅时删除对应映射。订阅名只能包含字母、
数字、点、下划线和连字符。保存后 `mihomo-config-regenerate.path` 会触发配置
验证；只有生成成功才会替换 `/var/lib/mihomo-config/config.yaml` 并重启服务。
原有 ClashTui `profiles` 目录和单订阅 `subscription.url` 会在首次切换时自动
迁移，旧文件不会被删除。

服务命令：

```bash
systemctl status mihomo
systemctl restart mihomo
journalctl -u mihomo -f
```

## 壁纸

壁纸文件直接存放在仓库：

```text
assets/wallpapers/
```

默认壁纸必须命名为：

```text
assets/wallpapers/default.png
```

随机和定时切换会递归识别：

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`

新增、删除或替换壁纸后需要重建系统，使文件进入新的 Nix store 路径：

```bash
rs
```

壁纸由 `awww` daemon 管理，恢复休眠后会自动重新应用默认壁纸。

## 自定义包与 Overlays

`overlays/default.nix` 组合以下 overlays：

| 包              | 用途                                                 |
| --------------- | ---------------------------------------------------- |
| `cc-switch-cli` | 固定上游源码提交，版本为 `5.9.2-unstable-2026-07-22` |
| `motrix-next`   | 更新到 `3.9.6`，并修复 sidecar 在 NixOS 上的动态链接 |

Vesktop 直接使用 nixpkgs 官方 `vesktop` 包，不再通过自定义 overlay 或二次打包安装。

仓库自己的包位于 `pkgs/`：

- `bili_tui`
- `fcitx5-pinyin-moegirl`
- `fcitx5-pinyin-zhwiki`
- `flake-stats-mcp`

## 目录结构

```text
.
├── assets/wallpapers/       # 由配置直接引用的壁纸文件
├── flake/modules/           # Flake 开发环境、格式化和 overlays 输出
├── home/                    # Home Manager 模块
│   ├── ai/                  # AI CLI、Codex 代理服务与 Context7 MCP 激活脚本
│   ├── dev/                 # 开发工具链
│   ├── editors/             # 编辑器
│   ├── programs/            # 桌面与 CLI 应用
│   ├── shell/               # Fish、Starship 和命令别名
│   ├── wall/                # awww 服务与默认壁纸
│   └── wm/sway/             # Sway 配置与快捷键
├── hosts/nixos/             # 当前物理机配置和硬件配置
├── lib/disko_layout/        # 普通与 LUKS 单盘布局
├── lib/scripts/             # 安装、分区和重建脚本
├── overlays/                # nixpkgs overlays
├── pkgs/                    # 仓库自有包
├── system/                  # NixOS 系统模块及统一聚合入口
├── flake.nix
├── justfile
└── me.nix                   # 用户名、Git 信息和初始密码哈希
```

配置入口遵循两条规则：

- `flake.nix` 只声明 inputs，并组合 `flake/modules/` 与 `hosts/`。
- 各目录的 `default.nix` 只负责聚合同目录模块，具体配置放在职责明确的文件中。

## 日常维护

仓库默认位于：

```text
~/mynixos-config
```

Fish 提供以下快捷命令：

| 命令 | 等价操作                                                               |
| ---- | ---------------------------------------------------------------------- |
| `rs` | `sudo nixos-rebuild switch --flake ~/mynixos-config#nixos 2>&1 \| nom` |
| `ru` | `nix flake update --flake ~/mynixos-config`                            |
| `rd` | 删除用户和系统旧世代，并回收不再引用的 store 路径                      |

典型更新流程：

```bash
ru
rs
```

需要释放空间时：

```bash
rd
```

> `rd` 会不可逆地删除旧 generations，删除后无法回滚到这些系统版本。

也可以使用仓库脚本。`just rebuild-switch` 会先执行 `nix flake check` 和 `nix fmt`，再交互选择主机并切换：

```bash
nix develop
just rebuild-switch
```

其他检查命令：

```bash
nix flake check
nix fmt
nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel
```

## Sway 快捷键

`Mod` 为 `Super`。

### 启动与系统

| 按键                       | 功能             |
| -------------------------- | ---------------- |
| `Mod` + `Return`           | 打开 Kitty       |
| `Mod` + `Shift` + `Return` | 打开浮动 Kitty   |
| `Mod` + `z`                | Rofi 应用启动器  |
| `Mod` + `v`                | Rofi 剪贴板历史  |
| `Mod` + `Shift` + `p`      | Rofi 电源菜单    |
| `Mod` + `Shift` + `b`      | Firefox          |
| `Mod` + `Shift` + `t`      | Telegram         |
| `Mod` + `Shift` + `q`      | QQ               |
| `Mod` + `Shift` + `v`      | Vesktop          |
| `Alt` + `Shift` + `q`      | 切换到 QQ 工作区 |
| `Alt` + `Shift` + `t`      | 切换到 TG 工作区 |
| `Alt` + `Shift` + `w`      | 切换到 WC 工作区 |
| `Alt` + `Shift` + `b`      | 切换到 Ff 工作区 |
| `Alt` + `Shift` + `v`      | 切换到 VT 工作区 |
| `Alt` + `Shift` + `s`      | 启动 SPlayer     |
| `Mod` + `Shift` + `x`      | 锁屏             |
| `Mod` + `Shift` + `c`      | 重载 Sway        |
| `Mod` + `Shift` + `e`      | 退出 Sway        |
| `Mod` + `o`                | 切换 Waybar 显示 |

### 窗口与工作区

| 按键                                 | 功能                       |
| ------------------------------------ | -------------------------- |
| `Mod` + `h/j/k/l` 或方向键           | 移动焦点                   |
| `Mod` + `Shift` + `h/j/k/l` 或方向键 | 移动窗口                   |
| `Mod` + `q`                          | 关闭窗口                   |
| `Mod` + `f`                          | 全屏切换                   |
| `Mod` + `Shift` + `Space`            | 浮动/平铺切换              |
| `Mod` + `Space`                      | 在浮动区和平铺区间切换焦点 |
| `Mod` + `1` 到 `0`                   | 切换工作区 1 到 10         |
| `Mod` + `Shift` + `1` 到 `0`         | 移动窗口到工作区           |
| `Mod` + `Ctrl` + `1` 到 `0`          | 移动窗口并跟随到工作区     |
| `Mod` + `/`                          | 当前与上一个工作区切换     |
| `Mod` + `.` / `,`                    | 下一个/上一个工作区        |
| `Mod` + `-` / `=`                    | 放入/取出 scratchpad       |
| `Mod` + `r`                          | 进入窗口大小调整模式       |
| `Mod` + `g`                          | 关闭窗口间隙               |
| `Mod` + `Shift` + `g`                | 恢复窗口间隙               |

### 截图

| 按键        | 功能                                         |
| ----------- | -------------------------------------------- |
| `Print`     | 打开 Flameshot GUI                           |
| `Mod` + `[` | Grimshot 交互截图，复制并保存到 `~/Pictures` |
| `Mod` + `]` | Grimshot 交互截图，仅复制到剪贴板            |
| `Mod` + `a` | Grimshot 交互截图，复制并保存到 `~/Pictures` |

截图不添加水印、阴影或边框。

### 壁纸

| 按键                           | 功能                                 |
| ------------------------------ | ------------------------------------ |
| `Mod` + `Shift` + `w`          | 从 `assets/wallpapers/` 随机选择一次 |
| `Mod` + `Ctrl` + `w`           | 启动每 120 秒随机切换                |
| `Mod` + `Ctrl` + `Shift` + `w` | 停止轮换并恢复 `default.png`         |

## 全新安装

### 1. 启动安装环境

从 NixOS Minimal ISO 启动，连接网络并克隆仓库：

```bash
git clone <你的仓库地址> mynixos-config
cd mynixos-config
nix develop --extra-experimental-features 'nix-command flakes'
```

### 2. 修改个人与硬件配置

至少检查：

- `me.nix`
- `hosts/nixos/default.nix`
- `hosts/nixos/hardware-configuration.nix`
- `lib/disko_layout/single-device.nix`
- `lib/disko_layout/single-device-luks.nix`

不要直接复用当前机器的磁盘 UUID、设备路径或密码哈希。

### 3. 分区

```bash
just disko
```

脚本会：

1. 发现 flake 中的 NixOS 主机。
2. 选择普通单盘或 LUKS 单盘布局。
3. 允许检查和编辑布局。
4. 要求输入 `YES` 后才擦除、格式化并挂载磁盘。
5. 生成硬件配置并复制仓库到 `/mnt/etc/nixos/flakes`。

> 该操作会清空目标磁盘。执行前必须确认布局中的设备路径。

### 4. 安装

系统 activation 会创建空的 Mihomo 订阅文件和仅包含 `DIRECT` 的初始配置，
因此安装前不需要把订阅 URL 写入目标磁盘。直接安装系统：

```bash
just install
```

首次进入新系统后，使用 `mihomo-sub add NAME` 添加订阅。

安装脚本会设置用户密码，并运行：

```bash
nixos-install --no-root-passwd --flake .#nixos
```

安装完成后重启：

```bash
reboot
```

### 5. 首次登录

登录后将仓库放到 `~/mynixos-config`。后续修改统一使用：

```bash
sudo nixos-rebuild switch --flake ~/mynixos-config#nixos
```

## 注意事项

- 当前用户配置使用 `home-manager.useUserPackages = true`。修改 Home Manager 包后应执行完整的 `nixos-rebuild switch`，只运行独立 Home Manager activation 不会更新 `/etc/profiles/per-user/<user>/bin`。
- `NIX_AUTO_RUN=1` 已启用，未安装的命令可能由 comma 临时运行。常用命令应显式加入系统或 Home Manager 包列表，避免意外使用 nix-index 中的旧版本。
- `sudo` 和 `doas` 当前均对 wheel 用户配置为免密码，仅适合受控的个人机器。
- `me.nix` 包含密码哈希和个人信息；公开仓库前应评估是否需要迁移到 sops-nix。
- `nix.gc` 每周运行并删除两天前的旧引用；手动 `rd` 会进行更彻底的旧世代清理。

## 参考

- [NixOS](https://nixos.org/)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Disko](https://github.com/nix-community/disko)
- [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)
