#!/bin/bash
# Install Claude Code from GitHub Releases.
# The installed version is pinned here; use tools/github-release-latest.sh to check updates.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
CLAUDE_BIN="${BIN_DIR}/claude"
CLAUDE_CODE_VERSION="2.1.193"
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

for dep in curl find head install mktemp tar uname; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

if [[ -x "$CLAUDE_BIN" ]]; then
    echo "Claude Code 已安装: $CLAUDE_BIN"
    "$CLAUDE_BIN" --version
    exit 0
fi

os=$(uname -s)
arch=$(uname -m)

case "$os:$arch" in
    Linux:x86_64 | Linux:amd64)
        target="linux-x64"
        ;;
    Linux:aarch64 | Linux:arm64)
        target="linux-arm64"
        ;;
    Darwin:x86_64)
        target="darwin-x64"
        if [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" == "1" ]]; then
            target="darwin-arm64"
        fi
        ;;
    Darwin:arm64 | Darwin:aarch64)
        target="darwin-arm64"
        ;;
    *)
        echo "错误: 不支持的平台 ${os}/${arch}"
        exit 1
        ;;
esac

tmp_dir=$(mktemp -d)
tarball="${tmp_dir}/claude.tar.gz"
url="https://github.com/anthropics/claude-code/releases/download/v${CLAUDE_CODE_VERSION}/claude-${target}.tar.gz"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "下载 Claude Code ${CLAUDE_CODE_VERSION} (${target})..."
curl -fL "$url" -o "$tarball"
tar -xzf "$tarball" -C "$tmp_dir"

claude_binary=$(find "$tmp_dir" -type f -name claude | head -1)
if [[ -z "$claude_binary" ]]; then
    echo "错误: Claude Code 压缩包中没有找到 claude"
    exit 1
fi

mkdir -p "$BIN_DIR"
install -m 755 "$claude_binary" "$CLAUDE_BIN"

echo "Claude Code 安装完成: $CLAUDE_BIN"
"$CLAUDE_BIN" --version
