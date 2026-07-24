#!/bin/bash
# Install or update Codex CLI binary from GitHub Releases.
# The installed version is pinned here; use tools/github-release-latest.sh to check updates.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
CODEX_BIN="${BIN_DIR}/codex"
CODEX_VERSION="0.145.0"
CURL_USER_AGENT="configs-install-codex"
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

for dep in curl sed tar find install uname mktemp; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

target_tag="rust-v${CODEX_VERSION}"

local_codex=""
if [[ -x "$CODEX_BIN" ]]; then
    local_codex="$CODEX_BIN"
else
    local_codex="$(command -v codex 2>/dev/null || true)"
fi

local_version=""
if [[ -n "$local_codex" ]]; then
    local_version=$("$local_codex" --version 2>/dev/null | sed -n 's/.* \([0-9][0-9.]*\).*/\1/p' | head -1)
fi

compare_versions() {
    local left="$1"
    local right="$2"
    local IFS=.
    local left_parts right_parts index left_part right_part

    read -r -a left_parts <<< "$left"
    read -r -a right_parts <<< "$right"

    for index in 0 1 2; do
        left_part="${left_parts[$index]:-0}"
        right_part="${right_parts[$index]:-0}"
        left_part="${left_part%%[^0-9]*}"
        right_part="${right_part%%[^0-9]*}"
        left_part="${left_part:-0}"
        right_part="${right_part:-0}"

        if ((10#$left_part < 10#$right_part)); then
            echo -1
            return
        fi
        if ((10#$left_part > 10#$right_part)); then
            echo 1
            return
        fi
    done

    echo 0
}

should_install=false
if [[ -z "$local_codex" || -z "$local_version" ]]; then
    echo "Codex 未安装，将安装目标版本 ${CODEX_VERSION}"
    should_install=true
else
    echo "当前 Codex: ${local_version} (${local_codex})"
    echo "目标 Codex: ${CODEX_VERSION}"

    version_cmp=$(compare_versions "$local_version" "$CODEX_VERSION")
    if [[ "$version_cmp" == "0" ]]; then
        echo "Codex 已是目标版本"
        exit 0
    fi

    if [[ "$version_cmp" == "1" ]]; then
        echo "本地 Codex 版本高于目标版本，不执行更新"
        exit 0
    fi

    answer=""
    read -r -p "是否更新 Codex 到 ${CODEX_VERSION}? [y/N] " answer || true
    case "$answer" in
        y | Y | yes | YES) should_install=true ;;
        *) echo "已取消更新"; exit 0 ;;
    esac
fi

if [[ "$should_install" != "true" ]]; then
    exit 0
fi

os=$(uname -s)
arch=$(uname -m)

case "$os:$arch" in
    Linux:x86_64) target="x86_64-unknown-linux-musl" ;;
    Linux:aarch64 | Linux:arm64) target="aarch64-unknown-linux-musl" ;;
    Darwin:x86_64) target="x86_64-apple-darwin" ;;
    Darwin:arm64 | Darwin:aarch64) target="aarch64-apple-darwin" ;;
    *) echo "错误: 不支持的平台 ${os}/${arch}"; exit 1 ;;
esac

tmp_dir=$(mktemp -d)
tarball="${tmp_dir}/codex.tar.gz"
url="https://github.com/openai/codex/releases/download/${target_tag}/codex-${target}.tar.gz"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "下载 Codex ${CODEX_VERSION} (${target})..."
curl -fL -H "User-Agent: ${CURL_USER_AGENT}" "$url" -o "$tarball"
tar -xzf "$tarball" -C "$tmp_dir"

codex_binary=$(find "$tmp_dir" -type f \( -name "codex-${target}" -o -name codex \) | head -1)
if [[ -z "$codex_binary" ]]; then
    echo "错误: Codex 压缩包中没有找到二进制文件"
    exit 1
fi

mkdir -p "$BIN_DIR"
install -m 755 "$codex_binary" "$CODEX_BIN"

echo "Codex 安装完成: $CODEX_BIN"
"$CODEX_BIN" --version
