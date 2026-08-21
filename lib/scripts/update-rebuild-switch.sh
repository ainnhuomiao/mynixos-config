#!/usr/bin/env bash
# Complete system update: flake update → check → format → build+switch TWICE
# (registry snapshot needs two rebuilds to consume the new nixpkgs) → verify →
# Firefox langpack sync (firefox-bin ships en-US only; langpack goes appDisabled
# on version bump). Follows the verified mynixos-config update workflow
# (2026-08-20). Manual extras from the full workflow:
#   - caelestia-shell 汉化 patch 重生成 (python3 ~/hanhua_drive.py) — only when
#     that input updated; this script warns but does not run it
#   - 清理旧代际: just clean
#
# Stops on first failure. After any failure, restore with:
#   git checkout -- flake.lock   (running system is decoupled from the lock)

set -euo pipefail

export NIX_CONFIG="experimental-features = nix-command flakes"
cd "$(dirname "$0")/../.."

echo "=== [1/7] 更新所有 flake inputs (nix flake update) ==="
nix flake update --log-format internal-json -v 2>&1 | nom --json

echo "=== [2/7] 检测 caelestia-shell 是否更新（需重新生成汉化 patch）==="
CAELESTIA_CHANGED=0
if git diff --quiet flake.lock; then
  echo "flake.lock 无改动，caelestia-shell 未更新"
else
  if git diff flake.lock | grep -qE '^[+-]    "caelestia-shell"'; then
    CAELESTIA_CHANGED=1
    echo "⚠️  caelestia-shell 已更新：请手动运行 python3 ~/hanhua_drive.py 重新生成汉化 patch，然后重跑本脚本"
    echo "    （命中率 647/659 正常；大幅下降=上游字符串变了）"
  else
    echo "caelestia-shell 未更新"
  fi
fi

echo "=== [3/7] 静态检查 (nix flake check) ==="
if ! nix flake check --fallback --log-format internal-json -v 2>&1 | nom --json; then
  echo "❌ nix flake check 失败"
  if ! curl -s -o /dev/null -w "%{http_code}" --max-time 15 https://cache.nixos.org/nix-cache-info | grep -q 200; then
    echo "   cache.nixos.org 不可达（环境问题），跳过 check 继续"
  else
    exit 1
  fi
fi

echo "=== [4/7] 格式化 (nix fmt) ==="
nix fmt

echo "=== [5/7] 构建安全网 (nh os build) ==="
nh os build . -H nixos

echo "=== [6/7] 两次切换 (registry 快照需两次 rebuild 才消费新 nixpkgs) ==="
NIX_CONFIG="$NIX_CONFIG" bash ./lib/scripts/rebuild.sh
NIX_CONFIG="$NIX_CONFIG" bash ./lib/scripts/rebuild.sh

echo "=== [7/7] Firefox 语言包同步 ==="
bash ./lib/scripts/firefox-langpack-sync.sh

echo "=== 完成。验证： ==="
echo "  readlink /run/current-system"
echo "  nix eval --raw .#nixosConfigurations.nixos.config.system.nixos.version"
echo "  jq -r '.flakes[0].to | .rev' /etc/nix/registry.json"
echo "  清理旧代际: just clean"
echo "  提交: git add flake.lock && git commit && git push"
