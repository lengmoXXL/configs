#!/bin/bash

# 安装 markdown-oxide LSP Server
# https://github.com/Feel-ix-343/markdown-oxide

set -e

INSTALL_DIR="${HOME}/.local/bin"
PROXY="${GITHUB_PROXY:-https://gh-proxy.com/}"
VERSION="v0.25.10"

echo "Installing markdown-oxide ${VERSION}..."

mkdir -p "$INSTALL_DIR"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)    ARCH="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) ARCH="aarch64-unknown-linux-gnu" ;;
    *)         echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

DOWNLOAD_URL="${PROXY}https://github.com/Feel-ix-343/markdown-oxide/releases/download/${VERSION}/markdown-oxide-${VERSION}-${ARCH}.tar.gz"

echo "Downloading from $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$TMPDIR/markdown-oxide.tar.gz"
tar xzf "$TMPDIR/markdown-oxide.tar.gz" -C "$TMPDIR"

cp "$TMPDIR/markdown-oxide-${VERSION}-${ARCH}/markdown-oxide" "$INSTALL_DIR/"
chmod +x "${INSTALL_DIR}/markdown-oxide"

echo ""
echo "✓ markdown-oxide ${VERSION} installed to ${INSTALL_DIR}/markdown-oxide"
echo "Verify: markdown-oxide --version"