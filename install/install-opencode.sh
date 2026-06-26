#!/bin/bash
# 安装 opencode

set -e

INSTALL_URL="https://opencode.ai/install"

echo "安装 opencode..."
curl -fsSL "$INSTALL_URL" | bash

echo "opencode 安装脚本执行完成"
