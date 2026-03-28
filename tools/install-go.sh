#!/bin/bash
# 安装 Go 到 ~/.local/go
# 可重入：已安装时跳过

set -e

INSTALL_DIR="${HOME}/.local/go"
BIN_DIR="${HOME}/.local/bin"

# 检查是否已安装
if [[ -x "$INSTALL_DIR/bin/go" ]]; then
    echo "Go 已安装: $($INSTALL_DIR/bin/go version)"
    exit 0
fi

echo "安装 Go 到: $INSTALL_DIR"

# 获取最新稳定版本
echo "获取最新版本..."
GO_VERSION=$(curl -sL "https://go.dev/VERSION?m=text" | head -1 | sed 's/go//')

if [[ -z "$GO_VERSION" ]]; then
    echo "错误：无法获取 Go 版本"
    exit 1
fi

echo "版本: $GO_VERSION"

# 确定架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
esac

# 下载地址（使用 golang.google.cn 镜像）
DOWNLOAD_URL="https://golang.google.cn/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"

mkdir -p "$BIN_DIR"

echo "下载中..."
curl -fL "$DOWNLOAD_URL" -o /tmp/go.tar.gz

echo "解压中..."
tar -xzf /tmp/go.tar.gz -C "${HOME}/.local"
rm /tmp/go.tar.gz

# 创建符号链接
ln -sf "$INSTALL_DIR/bin/go" "$BIN_DIR/go"
ln -sf "$INSTALL_DIR/bin/gofmt" "$BIN_DIR/gofmt"

# 配置 GOPATH 和 GOPROXY
ENV_DIR="$HOME/.config/env.d"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/go.sh" << 'EOF'
# Go 环境配置
export GOPATH="$HOME/.local/go-packages"
export GOPROXY="https://goproxy.cn,direct"
EOF

echo ""
echo "Go 安装完成"
echo "  go: $($INSTALL_DIR/bin/go version)"
echo "  GOPATH: ~/.local/go-packages"
echo "  GOPROXY: https://goproxy.cn,direct"
echo ""
echo "请运行 'source ~/.bashrc' 使环境变量生效"