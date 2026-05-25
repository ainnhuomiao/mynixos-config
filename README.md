# mynixos-config

基于 Nix Flakes 的个人 NixOS 配置。

## 主机

| 主机 | 类型 | 说明 |
|------|------|------|
| `nixos` | 物理机 | 完整桌面环境配置 |

## 特性

- **Flake** — 声明式、可复现的系统配置
- **Home Manager** — 用户级应用与 dotfiles 管理
- **Disko** — 声明式磁盘分区
- **Lanzaboote** — Secure Boot 支持
- **SOPS** — 加密管理敏感信息
- **Impermanence** — 无状态系统（可选）
- **Dae** — 透明代理

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/ainnhuomiao/mynixos-config.git

# 进入开发环境
cd mynixos-config
nix develop --extra-experimental-features 'nix-command flakes'

# 应用配置
just rebuild-switch
```

## 参考

- 原始配置来源: [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)
