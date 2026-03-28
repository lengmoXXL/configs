#!/bin/bash

# 安装 Marksman Markdown LSP Server
# https://github.com/artempyanykh/marksman

set -e

INSTALL_DIR="${HOME}/.local/bin"
PROXY="${GITHUB_PROXY:-https://ghproxy.com/}"

echo "Installing Marksman Markdown LSP Server..."

mkdir -p "$INSTALL_DIR"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)    ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)         echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

DOWNLOAD_URL="${PROXY}https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-${ARCH}"

echo "Downloading from $DOWNLOAD_URL"
curl -L -o "${INSTALL_DIR}/marksman" "$DOWNLOAD_URL"

chmod +x "${INSTALL_DIR}/marksman"

echo ""
echo "✓ Marksman installed to ${INSTALL_DIR}/marksman"
echo "Verify: marksman --version"