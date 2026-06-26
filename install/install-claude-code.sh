#!/bin/bash
# 安装 Claude Code

set -e

INSTALL_URL="https://claude.ai/install.sh"

echo "安装 Claude Code..."
curl -fsSL "$INSTALL_URL" | bash

echo "Claude Code 安装脚本执行完成"
