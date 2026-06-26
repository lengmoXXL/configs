#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/lengmoXXL/mytask.git"
USE_CN=false
GITHUB_PROXY_PREFIX="https://gh-proxy.com/"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="mytask"

usage() {
    cat << EOF
用法: $0 [-cn]

选项:
  -cn      通过国内代理 clone GitHub 仓库
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

for dep in git go mktemp; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

if [[ "$USE_CN" == "true" ]]; then
    REPO_URL="${GITHUB_PROXY_PREFIX}${REPO_URL}"
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Cloning repository..."
git clone "$REPO_URL" "$TMP_DIR/mytask"

echo "==> Building binary..."
cd "$TMP_DIR/mytask"
go build -o "$BINARY_NAME" ./cmd/mytask

echo "==> Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
mv "$BINARY_NAME" "$INSTALL_DIR/"

echo "==> Done! $BINARY_NAME installed to $INSTALL_DIR/$BINARY_NAME"
echo "Make sure $INSTALL_DIR is in your PATH"
