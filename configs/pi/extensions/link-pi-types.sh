#!/bin/bash
# 链接 pi 全局安装的类型包到本目录 node_modules，供 tsserver 解析。
# pi 运行时自行解析 @earendil-works/* 依赖，这里的链接只用于编辑器类型检查。

set -euo pipefail

EXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PI_BIN="$(command -v pi 2>/dev/null || true)"
if [[ -z "$PI_BIN" ]]; then
    echo "错误: 缺少 pi 命令，可先运行 ./install/install-pi-agent.sh"
    exit 1
fi

# npm 全局 bin 是指向包内 dist/cli.js 的软链，解析后取包根目录
PI_PKG="$(cd "$(dirname "$(readlink -f "$PI_BIN")")/.." && pwd)"
TUI_PKG="$PI_PKG/node_modules/@earendil-works/pi-tui"

for pkg in "$PI_PKG" "$TUI_PKG"; do
    if [[ ! -f "$pkg/package.json" ]]; then
        echo "错误: 未找到 $pkg"
        exit 1
    fi
done

mkdir -p "$EXT_DIR/node_modules/@earendil-works"
ln -sfn "$PI_PKG" "$EXT_DIR/node_modules/@earendil-works/pi-coding-agent"
ln -sfn "$TUI_PKG" "$EXT_DIR/node_modules/@earendil-works/pi-tui"

echo "已链接 pi 类型包:"
echo "  pi-coding-agent -> $PI_PKG"
echo "  pi-tui          -> $TUI_PKG"
