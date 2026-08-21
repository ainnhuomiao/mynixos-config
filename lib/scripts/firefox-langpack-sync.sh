#!/usr/bin/env bash
# Sync the Firefox zh-CN language pack to the active Firefox version.
#
# Why: pkgs.firefox-bin ships en-US ONLY; Chinese UI depends on the AMO langpack
# in the profile, which becomes appDisabled on every firefox version bump
# (strict_max pins the old version). The in-app download is useless because
# addons.mozilla.org is unreachable through this machine's proxy, while
# archive.mozilla.org works.
#
# When: run automatically at the end of `just rebuild-switch` (after activation),
# or manually via `just firefox-langpack`. No-op when the installed langpack
# already covers the target Firefox version. Kills + relaunches Firefox only
# when a swap is actually needed.
#
# Overridable for testing / other machines:
#   MOZ_DIR          (default ~/.mozilla/firefox)
#   FIREFOX_VERSION  (default: probed via `firefox --version`)
#   BACKUP_DIR       (default ~/.cache/firefox-langpack)

set -euo pipefail

MOZ_DIR="${MOZ_DIR:-$HOME/.mozilla/firefox}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.cache/firefox-langpack}"
LANGPACK_ID="langpack-zh-CN@firefox.mozilla.org"
ARCHIVE_BASE="https://archive.mozilla.org/pub/firefox/releases"

for tool in curl unzip jq pgrep pkill; do
  command -v "$tool" >/dev/null || {
    echo "❌ 缺少依赖: $tool" >&2
    exit 1
  }
done

# --- 1. Target version = the Firefox that will actually run -------------------
TARGET_VERSION="${FIREFOX_VERSION:-}"
if [ -z "$TARGET_VERSION" ]; then
  if command -v firefox >/dev/null; then
    TARGET_VERSION="$(firefox --version 2>/dev/null | grep -oE '[0-9]+\.[0-9.]+' | head -1 || true)"
  fi
fi
[ -n "$TARGET_VERSION" ] || {
  echo "❌ 无法确定 Firefox 版本（可设置 FIREFOX_VERSION）" >&2
  exit 1
}
echo "ℹ️  Firefox 目标版本: $TARGET_VERSION"

# --- 2. Active profile dir from profiles.ini -----------------------------------
[ -f "$MOZ_DIR/profiles.ini" ] || {
  echo "❌ 未找到 $MOZ_DIR/profiles.ini" >&2
  exit 1
}
PROFILE_PATH="$(awk -F= '/^\[Profile/{p=""} /^Path=/{p=$2} /^Default=1/{print p; exit}' "$MOZ_DIR/profiles.ini")"
PROFILE_PATH="${PROFILE_PATH:-$(awk -F= '/^Path=/{print $2; exit}' "$MOZ_DIR/profiles.ini")}"
[ -n "$PROFILE_PATH" ] || {
  echo "❌ profiles.ini 中没有找到 Profile 路径" >&2
  exit 1
}
EXT_DIR="$MOZ_DIR/$PROFILE_PATH/extensions"
XPI="$EXT_DIR/$LANGPACK_ID.xpi"

# --- 3. Does the installed langpack already cover the target version? ----------
ver_ge() { # $1 >= $2 ?  (normalizes trailing .* wildcards)
  local a="${1/\*/999}" b="${2/\*/999}"
  [ "$(printf '%s\n%s' "$a" "$b" | sort -V | tail -1)" = "$a" ]
}
langpack_covers() { # $1 = xpi path, $2 = target version
  local min max
  min="$(unzip -p "$1" manifest.json 2>/dev/null | jq -r '.browser_specific_settings.gecko.strict_min_version // empty' 2>/dev/null || true)"
  max="$(unzip -p "$1" manifest.json 2>/dev/null | jq -r '.browser_specific_settings.gecko.strict_max_version // empty' 2>/dev/null || true)"
  [ -n "$min" ] && [ -n "$max" ] && ver_ge "$2" "$min" && ver_ge "$max" "$2"
}

CURRENT_VERSION=""
if [ -f "$XPI" ]; then
  CURRENT_VERSION="$(unzip -p "$XPI" manifest.json 2>/dev/null | jq -r '.version // empty' 2>/dev/null || true)"
fi
echo "ℹ️  当前语言包版本: ${CURRENT_VERSION:-<none>}"

if [ -f "$XPI" ] && langpack_covers "$XPI" "$TARGET_VERSION"; then
  echo "✅ 语言包已覆盖 Firefox $TARGET_VERSION，无需操作"
  exit 0
fi

# --- 4. Download the matching langpack -----------------------------------------
TMP_XPI="$(mktemp --suffix=.xpi)"
trap 'rm -f "$TMP_XPI"' EXIT
URL="$ARCHIVE_BASE/$TARGET_VERSION/linux-x86_64/xpi/zh-CN.xpi"
echo "⬇️  下载语言包: $URL"
curl -fsSL --max-time 120 -o "$TMP_XPI" "$URL" || {
  echo "❌ 下载失败（archive.mozilla.org 可能没有版本 $TARGET_VERSION 的语言包）" >&2
  exit 1
}
langpack_covers "$TMP_XPI" "$TARGET_VERSION" || {
  echo "❌ 下载的语言包与 Firefox $TARGET_VERSION 不兼容，已中止" >&2
  exit 1
}

# --- 5. Close Firefox if running (swap would be clobbered / read mid-session) ---
firefox_running() { pgrep -x firefox >/dev/null || pgrep -x firefox-bin >/dev/null; }
WAS_RUNNING=0
if firefox_running; then
  WAS_RUNNING=1
  echo "🔄 正在关闭 Firefox..."
  pkill -x firefox 2>/dev/null || true
  pkill -x firefox-bin 2>/dev/null || true
  for _ in $(seq 1 30); do
    firefox_running || break
    sleep 1
  done
  firefox_running && {
    echo "❌ Firefox 未能完全退出，请手动关闭后重试" >&2
    exit 1
  }
  for _ in $(seq 1 10); do
    [ -L "$MOZ_DIR/$PROFILE_PATH/lock" ] || break
    sleep 1
  done
fi

# --- 6. Install (backup old) ----------------------------------------------------
mkdir -p "$BACKUP_DIR" "$EXT_DIR"
if [ -f "$XPI" ]; then
  cp "$XPI" "$BACKUP_DIR/$LANGPACK_ID-$(date +%Y%m%d-%H%M%S).xpi"
  echo "💾 旧语言包已备份到 $BACKUP_DIR"
  rm -f "$XPI"
fi
mv "$TMP_XPI" "$XPI"
chmod 644 "$XPI"
INSTALLED_VERSION="$(unzip -p "$XPI" manifest.json | jq -r '.version')"
echo "✅ 语言包已安装: $INSTALLED_VERSION"

# --- 7. Relaunch Firefox if it was running, then verify -------------------------
if [ "$WAS_RUNNING" = 1 ]; then
  echo "🔄 正在重新启动 Firefox..."
  setsid nohup firefox >/dev/null 2>&1 &
  sleep 10
  EJ="$MOZ_DIR/$PROFILE_PATH/extensions.json"
  if [ -f "$EJ" ]; then
    STATE="$(jq -r --arg id "$LANGPACK_ID" '.addons[] | select(.id==$id) | "active=\(.active) appDisabled=\(.appDisabled) version=\(.version)"' "$EJ" 2>/dev/null || true)"
    if echo "$STATE" | grep -q 'active=true appDisabled=false'; then
      echo "✅ 已激活: $STATE"
    else
      echo "⚠️  语言包状态待确认（$STATE），重启 Firefox 后生效"
    fi
  fi
fi
