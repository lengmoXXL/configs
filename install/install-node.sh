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
LTS_VERSIONS=$(curl -sL https://nodejs.org/dist/index.json | grep '"lts":' | sed 's/.*"version":"\([^"]*\)".*/\1/')

# 检测 macOS 版本，选择兼容的 Node.js
# Node.js 20+ 需要 macOS 11+，旧系统使用 Node.js 18
NODE_VERSION=""
if [[ "$(uname -s)" == "Darwin" ]]; then
    MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "0")
    MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
    echo "macOS 版本: $MACOS_VERSION"

    if [[ "$MACOS_MAJOR" -lt 11 ]]; then
        # macOS 10.15 或更早，使用 Node.js 18 LTS
        NODE_VERSION=$(echo "$LTS_VERSIONS" | grep "^v18\." | head -1)
        echo "使用 Node.js 18 以兼容旧版 macOS"
    fi
fi

# 默认使用最新 LTS
if [[ -z "$NODE_VERSION" ]]; then
    NODE_VERSION=$(echo "$LTS_VERSIONS" | head -1)
fi

if [[ -z "$NODE_VERSION" ]]; then
    echo "错误：无法获取 Node.js 版本"
    exit 1
fi

echo "版本: $NODE_VERSION"

# 下载地址（使用淘宝镜像）
# 支持: linux-x64, linux-arm64, darwin-x64 (Intel Mac), darwin-arm64 (Apple Silicon)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;  # Linux aarch64 和 macOS arm64
esac

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

DOWNLOAD_URL="https://npmmirror.com/mirrors/node/${NODE_VERSION}/node-${NODE_VERSION}-${OS}-${ARCH}.tar.xz"

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

# 配置 npm prefix，确保全局安装的包在 ~/.local
"$INSTALL_DIR/bin/npm" config set prefix "$HOME/.local"

echo ""
echo "Node.js 安装完成"
echo "  node: $($INSTALL_DIR/bin/node --version)"
echo "  npm: $($INSTALL_DIR/bin/npm --version)"
echo "  registry: https://registry.npmmirror.com"
echo "  npm global packages will be installed to ~/.local/bin"