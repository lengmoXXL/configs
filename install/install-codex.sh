#!/bin/bash
# Install or update Codex CLI binary from GitHub Releases.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
CODEX_BIN="${BIN_DIR}/codex"
CODEX_API="https://api.github.com/repos/openai/codex/releases/latest"

for dep in curl sed tar find install uname mktemp; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

latest_tag=$(curl -fsSL "$CODEX_API" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
if [[ -z "$latest_tag" ]]; then
    echo "错误: 无法获取 Codex 最新版本"
    exit 1
fi

latest_version="${latest_tag#rust-v}"
latest_version="${latest_version#v}"
if [[ -z "$latest_version" ]]; then
    echo "错误: 无法解析 Codex 最新版本: $latest_tag"
    exit 1
fi

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
    echo "Codex 未安装，将安装最新版本 ${latest_version}"
    should_install=true
else
    echo "当前 Codex: ${local_version} (${local_codex})"
    echo "最新 Codex: ${latest_version}"

    version_cmp=$(compare_versions "$local_version" "$latest_version")
    if [[ "$version_cmp" == "0" ]]; then
        echo "Codex 已是最新版本"
        exit 0
    fi

    if [[ "$version_cmp" == "1" ]]; then
        echo "本地 Codex 版本高于 GitHub latest，不执行更新"
        exit 0
    fi

    answer=""
    read -r -p "是否更新 Codex 到 ${latest_version}? [y/N] " answer || true
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
url="https://github.com/openai/codex/releases/download/${latest_tag}/codex-${target}.tar.gz"

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "下载 Codex ${latest_version} (${target})..."
curl -fL "$url" -o "$tarball"
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
