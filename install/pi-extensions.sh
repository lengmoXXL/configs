#!/bin/bash
# 安装本仓库自研 Pi extensions 到 ~/.pi/agent/extensions
# 外部 packages 由 settings.json 的 packages 声明，pi 启动时自动安装

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools" && pwd)/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$SCRIPT_DIR/../configs/pi/extensions"
TARGET="$HOME/.pi/agent/extensions"

if [[ "${UPDATE:-}" == "1" && ! -d "$TARGET" ]]; then
    echo "未安装，跳过: $TARGET"
    exit 0
fi

mkdir -p "$TARGET"

pending_updates=()
for ext in "$EXT_DIR"/*.ts; do
    [[ -f "$ext" ]] || continue
    if ! cmp -s "$ext" "$TARGET/$(basename "$ext")"; then
        pending_updates+=("$(basename "$ext")")
    fi
done
pending_deletes=()
for installed in "$TARGET"/*.ts; do
    [[ -f "$installed" ]] || continue
    if [[ ! -f "$EXT_DIR/$(basename "$installed")" ]]; then
        pending_deletes+=("$(basename "$installed")")
    fi
done

if [[ ${#pending_updates[@]} -eq 0 && ${#pending_deletes[@]} -eq 0 ]]; then
    echo "已是最新: $TARGET"
    exit 0
fi

if [[ ${#pending_updates[@]} -gt 0 ]]; then
    printf '更新: %s\n' "${pending_updates[@]}"
fi
if [[ ${#pending_deletes[@]} -gt 0 ]]; then
    printf '删除: %s\n' "${pending_deletes[@]}"
fi

if [[ "${UPDATE:-}" == "1" ]]; then
    confirm_update "pi extensions" || exit 0
fi

if [[ ${#pending_updates[@]} -gt 0 ]]; then
    for ext in "${pending_updates[@]}"; do
        cp "$EXT_DIR/$ext" "$TARGET/"
    done
fi
if [[ ${#pending_deletes[@]} -gt 0 ]]; then
    for ext in "${pending_deletes[@]}"; do
        rm "$TARGET/$ext"
    done
fi
echo "pi extensions 已更新: $TARGET"
