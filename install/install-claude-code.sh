#!/bin/bash
# 安装 Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

INSTALL_URL="${CLAUDE_CODE_INSTALL_URL:-https://claude.ai/install.sh}"

echo "安装 Claude Code..."
curl -fsSL "$INSTALL_URL" | bash

echo "Claude Code 安装脚本执行完成"
