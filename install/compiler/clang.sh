#!/bin/bash
# 安装 clang/clangd - 使用 yum
# 可重入：已安装时跳过

set -e

if [[ "${UPDATE:-}" == "1" ]] && ! rpm -q clang &>/dev/null; then
    echo "未安装，跳过: clang"
    exit 0
fi

if rpm -q clang &>/dev/null; then
    echo "clang 已安装"
    clang --version | head -1
    exit 0
fi

echo "安装 clang..."
sudo yum install -y clang clang-tools-extra

echo ""
echo "clang 安装完成"
clang --version | head -1