#!/bin/bash
# 安装 Node.js 到 ~/.local/node
# 可重入：已安装时跳过

set -e

INSTALL_DIR="${HOME}/.local/node"
BIN_DIR="${HOME}/.local/bin"

# 检查是否已安装
if [[ -x "$INSTALL_DIR/bin/node" ]]; then
    echo "Node.js 已安装: $($INSTALL_DIR/bin/node --version)"
    exit 0
fi

echo "安装 Node.js 到: $INSTALL_DIR"

# 获取最新 LTS 版本号
echo "获取最新 LTS 版本..."
NODE_VERSION=$(curl -sL https://nodejs.org/dist/index.json | grep -m1 '"lts":' | sed 's/.*"version":"\([^"]*\)".*/\1/')

if [[ -z "$NODE_VERSION" ]]; then
    echo "错误：无法获取 Node.js 版本"
    exit 1
fi

echo "版本: $NODE_VERSION"

# 下载地址（使用淘宝镜像）
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64) ARCH="arm64" ;;
esac

DOWNLOAD_URL="https://npmmirror.com/mirrors/node/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.xz"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

echo "下载中..."
curl -fL "$DOWNLOAD_URL" -o /tmp/node.tar.xz
tar -xJf /tmp/node.tar.xz -C "$INSTALL_DIR" --strip-components=1
rm /tmp/node.tar.xz

# 创建符号链接
ln -sf "$INSTALL_DIR/bin/node" "$BIN_DIR/node"
ln -sf "$INSTALL_DIR/bin/npm" "$BIN_DIR/npm"
ln -sf "$INSTALL_DIR/bin/npx" "$BIN_DIR/npx"

# 配置 npm 淘宝镜像
"$INSTALL_DIR/bin/npm" config set registry https://registry.npmmirror.com

echo ""
echo "Node.js 安装完成"
echo "  node: $($INSTALL_DIR/bin/node --version)"
echo "  npm: $($INSTALL_DIR/bin/npm --version)"
echo "  registry: https://registry.npmmirror.com"