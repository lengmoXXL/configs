#!/bin/bash
# 安装本仓库自研 Pi extensions 到 ~/.pi/agent/extensions
# 外部 packages 由 settings.json 的 packages 声明，pi 启动时自动安装

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$SCRIPT_DIR/pi/extensions"
TARGET="$HOME/.pi/agent/extensions"

mkdir -p "$TARGET"
for ext in "$EXT_DIR"/*.ts; do
    [[ -f "$ext" ]] || continue
    cp "$ext" "$TARGET/"
    echo "安装: $(basename "$ext")"
done
