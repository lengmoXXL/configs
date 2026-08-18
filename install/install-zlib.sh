#!/bin/bash
# 安装 zlib (Z-Library CLI, https://github.com/heartleo/zlib) 到 ~/.local/bin
# The installed release tag is pinned here; use tools/github-release-latest.sh to check updates.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
ZLIB_BIN="${BIN_DIR}/zlib"
ZLIB_VERSION="v0.0.6"
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

for dep in curl tar find install mktemp sed uname; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

target_version="${ZLIB_VERSION#v}"

local_zlib=""
if [[ -x "$ZLIB_BIN" ]]; then
    local_zlib="$ZLIB_BIN"
else
    local_zlib="$(command -v zlib 2>/dev/null || true)"
fi

local_version=""
if [[ -n "$local_zlib" ]]; then
    local_version=$("$local_zlib" --version 2>/dev/null | sed -n 's/.*version \([0-9][0-9.]*\).*/\1/p' | head -1)
fi

if [[ -n "$local_zlib" && "$local_version" == "$target_version" ]]; then
    echo "zlib 已是目标版本 ${target_version} (${local_zlib})"
    exit 0
fi

if [[ -n "$local_zlib" ]]; then
    echo "当前 zlib: ${local_version:-未知版本} (${local_zlib})，将重装目标版本 ${ZLIB_VERSION}"
else
    echo "zlib 未安装，将安装目标版本 ${ZLIB_VERSION}"
fi

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$os" in
    linux | darwin) ;;
    *) echo "错误: 不支持的系统 $os"; exit 1 ;;
esac
case "$arch" in
    x86_64 | amd64) arch="x86_64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
esac

archive="zlib_${target_version}_${os}_${arch}.tar.gz"
url="https://github.com/heartleo/zlib/releases/download/${ZLIB_VERSION}/${archive}"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

tmp_dir=$(mktemp -d)
cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "下载 zlib ${ZLIB_VERSION} (${os}/${arch})..."
curl -fL "$url" -o "${tmp_dir}/${archive}"
tar -xzf "${tmp_dir}/${archive}" -C "$tmp_dir"

zlib_bin=$(find "$tmp_dir" -type f -name zlib | head -1)
if [[ -z "$zlib_bin" ]]; then
    echo "错误: 压缩包中没有找到 zlib"
    exit 1
fi

mkdir -p "$BIN_DIR"
install -m 755 "$zlib_bin" "$ZLIB_BIN"

echo "zlib 安装完成: $ZLIB_BIN"
"$ZLIB_BIN" --version
