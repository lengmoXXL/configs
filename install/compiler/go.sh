#!/bin/bash
# 安装 Go 到 ~/.local/go
# 可重入：已安装时跳过；UPDATE=1 时对比最新版按需更新

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tools" && pwd)/common.sh"

INSTALL_DIR="${HOME}/.local/go"
BIN_DIR="${HOME}/.local/bin"

if [[ "${UPDATE:-}" == "1" && ! -x "$INSTALL_DIR/bin/go" ]]; then
    echo "未安装，跳过: $INSTALL_DIR/bin/go"
    exit 0
fi

ENV_DIR="$HOME/.config/env.d"
tmp_env="$(mktemp)"
cat > "$tmp_env" << 'EOF'
# Go 环境配置
export GOPATH="$HOME/.local/go-packages"
export GOPROXY="https://goproxy.cn,direct"
EOF
write_file_if_changed "$ENV_DIR/go.sh" "$tmp_env"

should_install=false
if [[ ! -x "$INSTALL_DIR/bin/go" ]]; then
    should_install=true
elif [[ "${UPDATE:-}" != "1" ]]; then
    echo "Go 已安装: $($INSTALL_DIR/bin/go version)"
else
    installed_version="$("$INSTALL_DIR/bin/go" version | awk '{print $3}' | sed 's/go//')"
    echo "获取最新版本..."
    GO_VERSION=$(curl -sL "https://go.dev/VERSION?m=text" | head -1 | sed 's/go//')
    if [[ -z "$GO_VERSION" ]]; then
        echo "错误：无法获取 Go 版本"
        exit 1
    fi
    if [[ "$installed_version" == "$GO_VERSION" ]]; then
        echo "Go 已是最新: $installed_version"
    else
        confirm_update "go: $installed_version -> $GO_VERSION" || exit 0
        should_install=true
    fi
fi

if [[ "$should_install" == "true" ]]; then
    echo "安装 Go 到: $INSTALL_DIR"

    GO_VERSION="${GO_VERSION:-$(curl -sL "https://go.dev/VERSION?m=text" | head -1 | sed 's/go//')}"

    if [[ -z "$GO_VERSION" ]]; then
        echo "错误：无法获取 Go 版本"
        exit 1
    fi

    echo "版本: $GO_VERSION"

    OS=$(uname -s)
    case "$OS" in
        Linux) OS="linux" ;;
        Darwin) OS="darwin" ;;
        *)
            echo "错误：不支持的系统: $OS"
            exit 1
            ;;
    esac

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
    esac

    # 下载地址（使用 golang.google.cn 镜像）
    DOWNLOAD_URL="https://golang.google.cn/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz"

    mkdir -p "$BIN_DIR"

    echo "下载中..."
    curl -fL "$DOWNLOAD_URL" -o /tmp/go.tar.gz

    echo "解压中..."
    tar -xzf /tmp/go.tar.gz -C "${HOME}/.local"
    rm /tmp/go.tar.gz

    ln -sf "$INSTALL_DIR/bin/go" "$BIN_DIR/go"
    ln -sf "$INSTALL_DIR/bin/gofmt" "$BIN_DIR/gofmt"
fi

if [[ "${UPDATE:-}" == "1" ]]; then
    confirm_update "gopls 到最新版" || exit 0
fi
echo "安装 gopls..."
GOPATH="$HOME/.local/go-packages" GOPROXY="https://goproxy.cn,direct" \
    "$INSTALL_DIR/bin/go" install golang.org/x/tools/gopls@latest

GOPATH="$HOME/.local/go-packages" \
    ln -sf "$HOME/.local/go-packages/bin/gopls" "$BIN_DIR/gopls"

echo ""
echo "Go 安装完成"
echo "  go: $($INSTALL_DIR/bin/go version)"
echo "  gopls: $($BIN_DIR/gopls version 2>/dev/null | head -1)"
echo "  GOPATH: ~/.local/go-packages"
echo "  GOPROXY: https://goproxy.cn,direct"
echo ""
echo "请运行 'source ~/.bashrc' 使环境变量生效"
