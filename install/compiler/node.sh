#!/bin/bash
# 安装 Node.js 到 ~/.local/node
# 可重入：已安装时跳过；UPDATE=1 时对比最新 LTS 按需更新

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tools" && pwd)/common.sh"

INSTALL_DIR="${HOME}/.local/node"
BIN_DIR="${HOME}/.local/bin"

if [[ "${UPDATE:-}" == "1" && ! -x "$INSTALL_DIR/bin/node" ]]; then
    echo "未安装，跳过: $INSTALL_DIR/bin/node"
    exit 0
fi

sync_npm_config() {
    if [[ "$("$INSTALL_DIR/bin/npm" config get registry 2>/dev/null)" != "https://registry.npmmirror.com" ]]; then
        if [[ "${UPDATE:-}" == "1" ]] && ! confirm_update "npm registry -> npmmirror"; then
            return
        fi
        "$INSTALL_DIR/bin/npm" config set registry https://registry.npmmirror.com
        echo "npm registry 已更新"
    fi
    if [[ "$("$INSTALL_DIR/bin/npm" config get prefix 2>/dev/null)" != "$HOME/.local" ]]; then
        if [[ "${UPDATE:-}" == "1" ]] && ! confirm_update "npm prefix -> ~/.local"; then
            return
        fi
        "$INSTALL_DIR/bin/npm" config set prefix "$HOME/.local"
        echo "npm prefix 已更新"
    fi
}

should_install=false
if [[ ! -x "$INSTALL_DIR/bin/node" ]]; then
    should_install=true
elif [[ "${UPDATE:-}" != "1" ]]; then
    echo "Node.js 已安装: $($INSTALL_DIR/bin/node --version)"
else
    installed_version="$("$INSTALL_DIR/bin/node" --version)"
    echo "获取最新 LTS 版本..."
    NODE_VERSION=$(curl -sL https://nodejs.org/dist/index.json | grep '"lts":' | sed 's/.*"version":"\([^"]*\)".*/\1/' | head -1)
    if [[ -z "$NODE_VERSION" ]]; then
        echo "错误：无法获取 Node.js 版本"
        exit 1
    fi
    if [[ "$installed_version" == "$NODE_VERSION" ]]; then
        echo "Node.js 已是最新: $installed_version"
    else
        confirm_update "node: $installed_version -> $NODE_VERSION" || exit 0
        should_install=true
    fi
fi

if [[ "$should_install" == "true" ]]; then
    echo "安装 Node.js 到: $INSTALL_DIR"

    if [[ -z "${NODE_VERSION:-}" ]]; then
        echo "获取最新 LTS 版本..."
        LTS_VERSIONS=$(curl -sL https://nodejs.org/dist/index.json | grep '"lts":' | sed 's/.*"version":"\([^"]*\)".*/\1/')

        # Node.js 20+ 需要 macOS 11+，旧系统使用 Node.js 18
        NODE_VERSION=""
        if [[ "$(uname -s)" == "Darwin" ]]; then
            MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "0")
            MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
            echo "macOS 版本: $MACOS_VERSION"

            if [[ "$MACOS_MAJOR" -lt 11 ]]; then
                NODE_VERSION=$(echo "$LTS_VERSIONS" | grep "^v18\." | head -1)
                echo "使用 Node.js 18 以兼容旧版 macOS"
            fi
        fi

        if [[ -z "$NODE_VERSION" ]]; then
            NODE_VERSION=$(echo "$LTS_VERSIONS" | head -1)
        fi

        if [[ -z "$NODE_VERSION" ]]; then
            echo "错误：无法获取 Node.js 版本"
            exit 1
        fi
    fi

    echo "版本: $NODE_VERSION"

    # 下载地址（使用淘宝镜像）
    # 支持: linux-x64, linux-arm64, darwin-x64 (Intel Mac), darwin-arm64 (Apple Silicon)
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="x64" ;;
        aarch64|arm64) ARCH="arm64" ;;
    esac

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    DOWNLOAD_URL="https://npmmirror.com/mirrors/node/${NODE_VERSION}/node-${NODE_VERSION}-${OS}-${ARCH}.tar.xz"

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"

    echo "下载中..."
    curl -fL "$DOWNLOAD_URL" -o /tmp/node.tar.xz
    tar -xJf /tmp/node.tar.xz -C "$INSTALL_DIR" --strip-components=1
    rm /tmp/node.tar.xz

    ln -sf "$INSTALL_DIR/bin/node" "$BIN_DIR/node"
    ln -sf "$INSTALL_DIR/bin/npm" "$BIN_DIR/npm"
    ln -sf "$INSTALL_DIR/bin/npx" "$BIN_DIR/npx"
fi

sync_npm_config

echo ""
echo "Node.js 安装完成"
echo "  node: $($INSTALL_DIR/bin/node --version)"
echo "  npm: $($INSTALL_DIR/bin/npm --version)"
echo "  registry: https://registry.npmmirror.com"
echo "  npm global packages will be installed to ~/.local/bin"
