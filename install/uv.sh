#!/bin/bash
# 安装 uv 到 ~/.local/bin（python/工具链管理器，compiler/python.sh 等依赖它）
# 可重入：已安装时跳过；如需升级请提高 UV_VERSION

set -e

BIN_DIR="${HOME}/.local/bin"
UV_VERSION="0.12.9"
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

if command -v uv &>/dev/null; then
    echo "uv 已安装: $(uv --version)"
    exit 0
fi

os="$(uname -s)"
arch="$(uname -m)"
case "$os-$arch" in
    Darwin-arm64) target="aarch64-apple-darwin" ;;
    Darwin-x86_64) target="x86_64-apple-darwin" ;;
    Linux-x86_64) target="x86_64-unknown-linux-gnu" ;;
    Linux-aarch64) target="aarch64-unknown-linux-gnu" ;;
    *)
        echo "错误: 不支持的平台: $os-$arch" >&2
        exit 1
        ;;
esac

url="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${target}.tar.gz"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

echo "下载 uv ${UV_VERSION} (${target})..."
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
curl -fL "$url" -o "$tmp_dir/uv.tar.gz"
tar -xzf "$tmp_dir/uv.tar.gz" -C "$tmp_dir"

mkdir -p "$BIN_DIR"
install -m 755 "$tmp_dir/uv-${target}/uv" "$BIN_DIR/uv"
install -m 755 "$tmp_dir/uv-${target}/uvx" "$BIN_DIR/uvx"

echo "uv 安装完成: $($BIN_DIR/uv --version)"
