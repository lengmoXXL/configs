#!/bin/bash
# 安装 cc-switch-cli

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

INSTALL_URL=$(configs_github_url "https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh")

echo "安装 cc-switch-cli..."
curl -fsSL "$INSTALL_URL" | bash

echo "cc-switch-cli 安装脚本执行完成"
