#!/bin/bash
# 安装 dprint 到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
DPRINT_VERSION="0.56.1"
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

mkdir -p "$BIN_DIR"

for dep in curl unzip install; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

existing_dprint="$(command -v dprint 2>/dev/null || true)"
if [[ -z "$existing_dprint" && -x "$BIN_DIR/dprint" ]]; then
    existing_dprint="$BIN_DIR/dprint"
fi

if [[ -n "$existing_dprint" ]]; then
    echo "dprint 已安装: $existing_dprint"
    "$existing_dprint" --version | head -1
    exit 0
fi

version="$DPRINT_VERSION"

os=$(uname -s)
arch=$(uname -m)
case "$os" in
    Linux)
        case "$arch" in
            x86_64) target="x86_64-unknown-linux-gnu" ;;
            aarch64 | arm64) target="aarch64-unknown-linux-gnu" ;;
            *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
        esac
        ;;
    Darwin)
        case "$arch" in
            x86_64) target="x86_64-apple-darwin" ;;
            aarch64 | arm64) target="aarch64-apple-darwin" ;;
            *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
        esac
        ;;
    *)
        echo "错误: 不支持的操作系统 $os"
        exit 1
        ;;
esac

tmp_dir=$(mktemp -d)
zipfile="${tmp_dir}/dprint.zip"
url="https://github.com/dprint/dprint/releases/download/${version}/dprint-${target}.zip"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

echo "下载 dprint ${version}..."
curl -fL "$url" -o "$zipfile"
unzip -o -q "$zipfile" -d "$tmp_dir"

dprint_bin=$(find "$tmp_dir" -type f -name dprint | head -1)
if [[ -z "$dprint_bin" ]]; then
    echo "错误: dprint 压缩包中没有找到 dprint"
    rm -rf "$tmp_dir"
    exit 1
fi

install -m 755 "$dprint_bin" "$BIN_DIR/dprint"
rm -rf "$tmp_dir"

echo "dprint 安装完成: $BIN_DIR/dprint"
"$BIN_DIR/dprint" --version | head -1
