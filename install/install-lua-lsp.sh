#!/bin/bash

# 安装 lua-language-server 到 ~/.local/lua-language-server
# 可重入：已安装时跳过

set -e

INSTALL_DIR="${HOME}/.local/lua-language-server"
BIN_DIR="${HOME}/.local/bin"
BINARY="$BIN_DIR/lua-language-server"
VERSION="3.19.1"
USE_CN=false
GITHUB_RELEASE_PROXY="https://gh-proxy.com/"

usage() {
    cat << EOF
用法: $0 [-cn]

选项:
  -cn      通过国内代理下载 GitHub Release 文件
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

if [[ -x "$BINARY" ]]; then
    echo "lua-language-server 已安装"
    exit 0
fi

echo "安装 lua-language-server $VERSION"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    linux | darwin) ;;
    *) echo "不支持的操作系统: $OS"; exit 1 ;;
esac

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH="x64" ;;
    arm64 | aarch64) ARCH="arm64" ;;
    *)       echo "不支持的架构: $ARCH"; exit 1 ;;
esac
mkdir -p "$BIN_DIR"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"

TARBALL="lua-language-server-$VERSION-$OS-$ARCH.tar.gz"
DOWNLOAD_URL="https://github.com/LuaLS/lua-language-server/releases/download/$VERSION/$TARBALL"
if [[ "$USE_CN" == "true" ]]; then
    DOWNLOAD_URL="${GITHUB_RELEASE_PROXY}${DOWNLOAD_URL}"
fi
curl -fL "$DOWNLOAD_URL" -o "$TARBALL"

mkdir -p "$INSTALL_DIR"
tar -xzf "$TARBALL" -C "$INSTALL_DIR"
# 不能用符号链接：macOS 上二进制按 argv[0] 定位 main.lua，经链接调用会找错目录
cat > "$BINARY" << EOF
#!/bin/sh
exec "$INSTALL_DIR/bin/lua-language-server" "\$@"
EOF
chmod +x "$BINARY"

echo ""
echo "lua-language-server 安装完成: $BINARY"
