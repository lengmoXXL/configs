#!/bin/bash
# 安装 cc-switch-cli 到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
BINARY="${BIN_DIR}/cc-switch"
VERSION="v5.8.5"
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

for dep in curl tar find install uname mktemp; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

if [[ -x "$BINARY" ]]; then
    echo "cc-switch 已安装: $BINARY"
    "$BINARY" --version
    exit 0
fi

os=$(uname -s)
arch=$(uname -m)

case "$os:$arch" in
    Linux:x86_64) target="linux-x64-musl" ;;
    Linux:aarch64 | Linux:arm64) target="linux-arm64-musl" ;;
    Darwin:*) target="darwin-universal" ;;
    *) echo "错误: 不支持的平台 ${os}/${arch}"; exit 1 ;;
esac

tmp_dir=$(mktemp -d)
tarball="${tmp_dir}/cc-switch-cli.tar.gz"
url="https://github.com/SaladDay/cc-switch-cli/releases/download/${VERSION}/cc-switch-cli-${VERSION}-${target}.tar.gz"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

trap 'rm -rf "$tmp_dir"' EXIT

echo "下载 cc-switch-cli ${VERSION} (${target})..."
curl -fL "$url" -o "$tarball"
tar -xzf "$tarball" -C "$tmp_dir"

binary=$(find "$tmp_dir" -type f -name cc-switch | head -1)
if [[ -z "$binary" ]]; then
    echo "错误: cc-switch-cli 压缩包中没有找到 cc-switch"
    exit 1
fi

mkdir -p "$BIN_DIR"
install -m 755 "$binary" "$BINARY"

echo "cc-switch-cli 安装完成: $BINARY"
"$BINARY" --version
