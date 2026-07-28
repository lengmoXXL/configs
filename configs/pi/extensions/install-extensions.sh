#!/bin/bash
# 安装本目录的 Pi extensions 到 ~/.pi/agent/extensions

set -euo pipefail

EXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.pi/agent/extensions"

mkdir -p "$TARGET"
for ext in "$EXT_DIR"/*.ts; do
    cp "$ext" "$TARGET/"
    echo "安装: $(basename "$ext")"
done
