#!/bin/bash
# 安装 Go 到 ~/.local/go
# 可重入：已安装时跳过

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

INSTALL_DIR="${HOME}/.local/go"
BIN_DIR="${HOME}/.local/bin"

if configs_is_cn; then
    GO_VERSION_URL="${GO_VERSION_URL:-https://golang.google.cn/VERSION?m=text}"
    GO_DOWNLOAD_BASE="${GO_DOWNLOAD_BASE:-https://golang.google.cn/dl}"
else
    GO_VERSION_URL="${GO_VERSION_URL:-https://go.dev/VERSION?m=text}"
    GO_DOWNLOAD_BASE="${GO_DOWNLOAD_BASE:-https://go.dev/dl}"
fi

# 检查是否已安装
if [[ -x "$INSTALL_DIR/bin/go" ]]; then
    echo "Go 已安装: $($INSTALL_DIR/bin/go version)"
else
    echo "安装 Go 到: $INSTALL_DIR"

    # 获取最新稳定版本
    echo "获取最新版本..."
    GO_VERSION=$(curl -sL "$GO_VERSION_URL" | head -1 | sed 's/go//')

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

    DOWNLOAD_URL="${GO_DOWNLOAD_BASE%/}/go${GO_VERSION}.linux-${ARCH}.tar.gz"

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
EOF
    if configs_is_cn; then
        echo 'export GOPROXY="https://goproxy.cn,direct"' >> "$ENV_DIR/go.sh"
    fi
fi

# 安装 gopls
echo "安装 gopls..."
GOPATH="$HOME/.local/go-packages" GOPROXY="${GOPROXY:-direct}" \
    "$INSTALL_DIR/bin/go" install golang.org/x/tools/gopls@latest

# 创建 gopls 符号链接
GOPATH="$HOME/.local/go-packages" \
    ln -sf "$HOME/.local/go-packages/bin/gopls" "$BIN_DIR/gopls"

echo ""
echo "Go 安装完成"
echo "  go: $($INSTALL_DIR/bin/go version)"
echo "  gopls: $($BIN_DIR/gopls version 2>/dev/null | head -1)"
echo "  GOPATH: ~/.local/go-packages"
echo "  GOPROXY: ${GOPROXY:-direct}"
echo ""
echo "请运行 'source ~/.bashrc' 使环境变量生效"
