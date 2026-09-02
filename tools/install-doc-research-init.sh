#!/bin/bash
# 安装 doc-research-init 到 ~/.local/bin

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$BIN_DIR"
install -m 755 "$SCRIPT_DIR/doc-research-init.sh" "$BIN_DIR/doc-research-init"

echo "Installed doc-research-init to $BIN_DIR/doc-research-init"
echo "Run it with: doc-research-init [目标目录]"
