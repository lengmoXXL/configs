#!/bin/bash
# 安装 opencode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

INSTALL_URL="${OPENCODE_INSTALL_URL:-https://opencode.ai/install}"

echo "安装 opencode..."
curl -fsSL "$INSTALL_URL" | bash

echo "opencode 安装脚本执行完成"
