# mynixos-config

基于 Nix Flakes 的个人 NixOS 配置，使用 Sway 桌面环境。

## 主机

| 主机 | 类型 | 说明 |
|------|------|------|
| `nixos` | 物理机 | 完整桌面环境配置 (Sway WM) |

## 软件

### 系统

| 软件 | 说明 |
|------|------|
| **Sway** | Wayland 平铺窗口管理器，类 i3 体验 |
| **Waybar** | 状态栏、系统托盘、工作区指示器 |
| **swww** | 动态壁纸 |
| **Rofi** | 应用启动器、剪贴板历史、电源菜单 |
| **Mako** | 通知守护进程 |
| **Flameshot** | 截图工具 (支持水印/阴影) |
| **Fcitx5** | 中文输入法 |
| **GTK / Papirus** | 主题与图标 |
| **SOPS + Age** | 加密管理敏感信息 |
| **Lanzaboote** | Secure Boot 支持 |
| **Disko** | 声明式磁盘分区 |

### 终端

| 软件 | 说明 |
|------|------|
| **Kitty** | GPU 加速终端模拟器 |
| **Fish** | 现代化 Shell |
| **Starship** | 跨 Shell 提示符 |
| **Zoxide** | 智能目录跳转 (替代 cd) |
| **fzf** | 模糊搜索 |
| **ripgrep / fd / bat / delta** | 现代 CLI 工具集 |

### 浏览器

| 软件 | 说明 |
|------|------|
| **Firefox** | 开源浏览器 |
| **Microsoft Edge** | 备选浏览器 |
| **Zen** | 基于 Firefox 的社区浏览器 |

### 开发

| 软件 | 说明 |
|------|------|
| **Neovim** | 终端编辑器 (LazyVim) |
| **Helix** | 模态编辑器 |
| **Git** | 版本控制 |
| **Lazygit** | Git TUI |
| **Rust** | Rust 工具链 (via rust-overlay) |
| **Go** | Go 语言工具链 |
| **Haskell** | GHC + Cabal |
| **C/C++** | Clang + CMake + Meson + Ninja + Bear |
| **TypeScript / Node / Bun** | Web 开发 |
| **Protobuf / gRPC** | RPC 工具链 |
| **Direnv** | 按目录加载环境变量 |

### AI

| 软件 | 说明 |
|------|------|
| **Claude Code** | Anthropic CLI 编码助手 |
| **Gemini CLI** | Google AI 助手 |
| **GitHub Copilot CLI** | GitHub AI 助手 |
| **Codex (OpenAI)** | OpenAI CLI 编码助手 |
| **OpenCode** | 基于 Anomaly AI 的编码助手 |

### 通讯

| 软件 | 说明 |
|------|------|
| **Discord** | 语音/文字聊天 |
| **Telegram** | 即时通讯 |
| **QQ** | 即时通讯 |
| **WeChat** | 即时通讯 |
| **Feishu / ByteDance-Feishu** | 协作办公 |
| **Tencent Meeting** | 视频会议 |
| **Vesktop** | Discord 第三方客户端 |
| **Element Desktop** | Matrix 客户端 |
| **Thunderbird** | 邮件客户端 |

### 影音

| 软件 | 说明 |
|------|------|
| **mpv** | 视频播放器 |
| **mpd + ncmpcpp** | 本地音乐播放器 |
| **Splayer** | 网易云音乐客户端 |
| **Go-MusicFox** | 终端音乐播放器 |
| **Cava** | 终端音频可视化 |
| **Kdenlive** | 视频编辑器 |
| **OBS Studio** | 直播/录屏 |

### 工具

| 软件 | 说明 |
|------|------|
| **Bilibili** | 哔哩哔哩客户端 |
| **Bili Live TUI** | 终端 B 站直播 |
| **yt-dlp** | 视频下载工具 |
| **Yazi** | 终端文件管理器 |
| **Zathura** | PDF 阅读器 |
| **Fastfetch** | 系统信息工具 |
| **Kooha** | 屏幕录制 |
| **imv / swayimg** | 图片查看器 |
| **btop** | 系统资源监控 |
| **DBEaver** | 数据库管理工具 |
| **Emanote** | 个人知识库 |
| **nix-index / nix-locate** | Nix 包搜索 |

## 快速开始

```bash
git clone https://github.com/ainnhuomiao/mynixos-config.git
cd mynixos-config
nix develop --extra-experimental-features 'nix-command flakes'
just rebuild-switch
```

## Sway 按键操作

> Mod 键 = **Alt**

### 应用启动

| 按键 | 功能 |
|------|------|
| `Mod` + `Return` | 打开终端 (Kitty) |
| `Mod` + `Shift` + `Return` | 打开浮动终端 |
| `Mod` + `b` | Firefox |
| `Mod` + `t` | Telegram |
| `Mod` + `q` | QQ |
| `Mod` + `m` | 音乐播放器 |
| `Super` | Rofi 应用启动器 |
| `Mod` + `v` | Rofi 剪贴板历史 |
| `Mod` + `Super` | Rofi 电源菜单 |

### 窗口操作

| 按键 | 功能 |
|------|------|
| `Mod` + `h` / `j` / `k` / `l` | 移动焦点 (←↓↑→) |
| `Mod` + `←` / `↓` / `↑` / `→` | 移动焦点 (方向键) |
| `Mod` + `Shift` + `h`/`j`/`k`/`l` | 移动窗口 |
| `Mod` + `Shift` + `←`/`↓`/`↑`/`→` | 移动窗口 (方向键) |
| `Mod` + `Shift` + `p` | 关闭窗口 |
| `Mod` + `f` | 全屏切换 |
| `Mod` + `Shift` + `space` | 浮动/平铺切换 |
| `Mod` + `space` | 平铺区/浮动区焦点切换 |
| `Mod` + `-` | 窗口收入暂存区 |
| `Mod` + `=` | 从暂存区取出窗口 |
| `Mod` + `p` | 聚焦父容器 |
| `Mod` + `c` | 聚焦子容器 |

### 工作区

| 按键 | 功能 |
|------|------|
| `Mod` + `1` ~ `0` | 切换到工作区 1~10 |
| `Mod` + `Shift` + `1`~`0` | 移动窗口到工作区 |
| `Mod` + `Ctrl` + `1`~`0` | 移动窗口并跟随到工作区 |
| `Mod` + `/` | 切换到上一个工作区 |
| `Mod` + `.` | 下一个工作区 |
| `Mod` + `,` | 上一个工作区 |

### 布局

| 按键 | 功能 |
|------|------|
| `Mod` + `;` | 垂直分割 |
| `Mod` + `'` | 水平分割 |
| `Mod` + `s` | 堆叠布局 |
| `Mod` + `w` | 标签页布局 |
| `Mod` + `e` | 切换分割方向 |

### 调整窗口大小

| 按键 | 功能 |
|------|------|
| `Mod` + `r` | 进入大小调整模式 (h/j/k/l 或方向键) |
| `Shift` + `Ctrl` + `h`/`j`/`k`/`l` | 快速调整大小 (±5px) |

### 截图

| 按键 | 功能 |
|------|------|
| `Print` | 区域截图 (Flameshot + 水印+阴影) |
| `Mod` + `[` | 区域截图保存 (无水印) |
| `Mod` + `]` | 区域截图到剪贴板 (无水印) |
| `Mod` + `a` | 区域截图 (Grimshot + 水印+阴影) |

### 壁纸

| 按键 | 功能 |
|------|------|
| `Mod` + `Shift` + `w` | 随机切换壁纸 |
| `Mod` + `Ctrl` + `w` | 定时轮换壁纸 (每2分钟) |
| `Mod` + `Ctrl` + `Shift` + `w` | 恢复默认壁纸 |

### 其他

| 按键 | 功能 |
|------|------|
| `Mod` + `Shift` + `x` | 锁屏 |
| `Mod` + `Shift` + `c` | 重载 Sway 配置 |
| `Mod` + `Shift` + `e` | 退出 Sway |
| `Mod` + `o` | 切换 Waybar 显隐 |
| `Mod` + `g` | 关闭窗口间隙 |
| `Mod` + `Shift` + `g` | 开启窗口间隙 |

### 媒体键

| 按键 | 功能 |
|------|------|
| `XF86AudioRaiseVolume` | 音量 + |
| `XF86AudioLowerVolume` | 音量 - |
| `XF86AudioMute` | 静音 |
| `XF86AudioMicMute` | 麦克风静音 |
| `XF86MonBrightnessUp` / `Down` | 亮度调节 |
| `XF86AudioPlay` | 播放/暂停 |
| `XF86AudioNext` / `Prev` | 上一首/下一首 |

### Firefox 快捷键

| 按键 | 功能 |
|------|------|
| `Alt` + `b` | 启动 Firefox |
| `Ctrl` + `L` | 聚焦地址栏 |
| `Ctrl` + `T` | 新标签页 |
| `Ctrl` + `W` | 关闭标签页 |
| `Ctrl` + `Shift` + `T` | 恢复关闭的标签 |
| `Ctrl` + `Tab` | 切换标签页 |
| `Ctrl` + `1`~`8` | 切换到对应标签 |
| `Ctrl` + `F` | 页面内搜索 |
| `F5` / `Ctrl` + `R` | 刷新页面 |
| `F12` | 开发者工具 |

### 其他设置

- **CapsLock** = Escape
- 触摸板：轻触点击、自然滚动、中键模拟
- 窗口跟随鼠标：关闭
- 鼠标拖动窗口：`Mod` + 左键拖拽 / 右键调整大小
- 空闲 15 分钟自动挂起，挂起前自动锁屏
- 自适应同步 (VRR)

## 参考

- 原始配置来源: [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)
