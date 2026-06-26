#!/bin/bash
# 安装 cc-switch-cli

set -e

INSTALL_URL="https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh"

echo "安装 cc-switch-cli..."
curl -fsSL "$INSTALL_URL" | bash

echo "cc-switch-cli 安装脚本执行完成"
