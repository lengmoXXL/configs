#!/bin/bash
# Install Claude Code from GitHub Releases.
# The installed version is pinned here; use tools/github-release-latest.sh to check updates.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
CLAUDE_BIN="${BIN_DIR}/claude"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
CLAUDE_CODE_VERSION="2.1.197"
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

for dep in curl find head install jq mktemp sed tar uname; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

ensure_claude_onboarding() {
    local settings_dir tmp_file
    settings_dir="$(dirname "$CLAUDE_SETTINGS")"

    mkdir -p "$settings_dir"
    tmp_file="$(mktemp)"

    if [[ -f "$CLAUDE_SETTINGS" ]]; then
        if ! jq 'if type != "object" then error("Claude settings must be a JSON object") elif has("hasCompletedOnboarding") then . else . + {hasCompletedOnboarding: true} end' "$CLAUDE_SETTINGS" > "$tmp_file"; then
            rm -f "$tmp_file"
            echo "错误: 无法处理 Claude Code settings JSON: $CLAUDE_SETTINGS" >&2
            exit 1
        fi
    else
        printf '%s\n' '{"hasCompletedOnboarding":true}' > "$tmp_file"
    fi

    install -m 600 "$tmp_file" "$CLAUDE_SETTINGS"
    rm -f "$tmp_file"
}

local_claude=""
if [[ -x "$CLAUDE_BIN" ]]; then
    local_claude="$CLAUDE_BIN"
else
    local_claude="$(command -v claude 2>/dev/null || true)"
fi

local_version=""
if [[ -n "$local_claude" ]]; then
    local_version=$("$local_claude" --version 2>/dev/null | sed -n 's/^\([0-9][0-9.]*\).*/\1/p' | head -1)
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
if [[ -z "$local_claude" || -z "$local_version" ]]; then
    echo "Claude Code 未安装，将安装目标版本 ${CLAUDE_CODE_VERSION}"
    should_install=true
else
    echo "当前 Claude Code: ${local_version} (${local_claude})"
    echo "目标 Claude Code: ${CLAUDE_CODE_VERSION}"

    version_cmp=$(compare_versions "$local_version" "$CLAUDE_CODE_VERSION")
    if [[ "$version_cmp" == "0" ]]; then
        echo "Claude Code 已是目标版本"
        ensure_claude_onboarding
        exit 0
    fi

    if [[ "$version_cmp" == "1" ]]; then
        echo "本地 Claude Code 版本高于目标版本，不执行更新"
        exit 0
    fi

    answer=""
    read -r -p "是否更新 Claude Code 到 ${CLAUDE_CODE_VERSION}? [y/N] " answer || true
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
ensure_claude_onboarding
"$CLAUDE_BIN" --version
