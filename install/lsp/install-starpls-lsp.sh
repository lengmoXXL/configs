#!/bin/bash
# 安装 starpls (Starlark/Bazel LSP) 到 ~/.local/bin
# 可重入：已安装时跳过

set -e

BIN_DIR="${HOME}/.local/bin"
BINARY="${BIN_DIR}/starpls"
API_URL="https://api.github.com/repos/withered-magic/starpls/releases/latest"
PROXY="${GITHUB_PROXY:-https://gh-proxy.com/}"

if [[ -x "$BINARY" ]]; then
    echo "starpls 已安装: $BINARY"
    echo "  version: $("$BINARY" version)"
    exit 0
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="aarch64" ;;
    *) echo "错误: 不支持的架构 $ARCH"; exit 1 ;;
esac

RELEASE_JSON=$(curl -fsSL "$API_URL")
VERSION=$(printf "%s\n" "$RELEASE_JSON" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
ASSET="starpls-linux-${ARCH}"
DOWNLOAD_URL=$(printf "%s\n" "$RELEASE_JSON" | sed -n "s/.*\"browser_download_url\": *\"\([^\"]*\/${ASSET}\)\".*/\1/p" | head -1)

if [[ -z "$VERSION" || -z "$DOWNLOAD_URL" ]]; then
    echo "错误: 无法获取 starpls 最新版本下载地址"
    exit 1
fi

echo "安装 starpls $VERSION (${ARCH})"

mkdir -p "$BIN_DIR"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

curl -fL "${PROXY}${DOWNLOAD_URL}" -o "${TMPDIR}/starpls"
install -m 755 "${TMPDIR}/starpls" "$BINARY"

echo ""
echo "starpls 安装完成:"
echo "  starpls: $BINARY"
echo "  version: $("$BINARY" version)"
