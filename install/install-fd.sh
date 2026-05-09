#!/bin/bash
# 安装 fd 到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
FD_API="https://api.github.com/repos/sharkdp/fd/releases/latest"

mkdir -p "$BIN_DIR"

for dep in curl tar sed find install; do
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

version=$(curl -fsSL "$FD_API" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
if [[ -z "$version" ]]; then
    echo "错误: 无法获取 fd 最新版本"
    exit 1
fi

arch=$(uname -m)
case "$arch" in
    x86_64) target="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64) target="aarch64-unknown-linux-gnu" ;;
    *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
esac

tmp_dir=$(mktemp -d)
tarball="${tmp_dir}/fd.tar.gz"
url="https://github.com/sharkdp/fd/releases/download/${version}/fd-${version}-${target}.tar.gz"

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
