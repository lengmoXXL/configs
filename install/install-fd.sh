#!/bin/bash
# 安装 fd 到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
FD_VERSION="v10.4.2"
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

for dep in curl tar find install; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

existing_fd="$(command -v fd 2>/dev/null || true)"
if [[ -z "$existing_fd" && -x "$BIN_DIR/fd" ]]; then
    existing_fd="$BIN_DIR/fd"
fi

if [[ -n "$existing_fd" ]]; then
    echo "fd 已安装: $existing_fd"
    "$existing_fd" --version | head -1
    exit 0
fi

version="$FD_VERSION"

arch=$(uname -m)
case "$arch" in
    x86_64) target="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64) target="aarch64-unknown-linux-gnu" ;;
    *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
esac

tmp_dir=$(mktemp -d)
tarball="${tmp_dir}/fd.tar.gz"
url="https://github.com/sharkdp/fd/releases/download/${version}/fd-${version}-${target}.tar.gz"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

echo "下载 fd ${version}..."
curl -fL "$url" -o "$tarball"
tar -xzf "$tarball" -C "$tmp_dir"

fd_bin=$(find "$tmp_dir" -type f -name fd | head -1)
if [[ -z "$fd_bin" ]]; then
    echo "错误: fd 压缩包中没有找到 fd"
    rm -rf "$tmp_dir"
    exit 1
fi

install -m 755 "$fd_bin" "$BIN_DIR/fd"
rm -rf "$tmp_dir"

echo "fd 安装完成: $BIN_DIR/fd"
"$BIN_DIR/fd" --version | head -1
