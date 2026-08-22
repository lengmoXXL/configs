#!/bin/bash
# Install Hermes Agent using the upstream installer.
# The installed release tag is pinned here; use tools/github-release-latest.sh to check updates.

set -euo pipefail

HERMES_AGENT_TAG="v2026.8.19"
INSTALLER_URL="https://hermes-agent.nousresearch.com/install.sh"
SKIP_SETUP=true
SKIP_BROWSER=true
INCLUDE_DESKTOP=false

usage() {
    cat << EOF
用法: $0 [--setup] [--browser] [--include-desktop]

选项:
  --setup            安装后运行交互式 hermes setup
  --browser          同时安装浏览器工具依赖
  --include-desktop  同时构建 Hermes Desktop
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --setup)
            SKIP_SETUP=false
            ;;
        --browser)
            SKIP_BROWSER=false
            ;;
        --include-desktop)
            INCLUDE_DESKTOP=true
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

for dep in bash curl mktemp; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

tmp_dir=$(mktemp -d)
installer="${tmp_dir}/install-hermes-agent.sh"

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "下载 Hermes Agent installer ${HERMES_AGENT_TAG}..."
curl -fsSL "$INSTALLER_URL" -o "$installer"
chmod +x "$installer"

args=(--branch "$HERMES_AGENT_TAG" --non-interactive)
if [[ "$SKIP_SETUP" == "true" ]]; then
    args+=(--skip-setup)
fi
if [[ "$SKIP_BROWSER" == "true" ]]; then
    args+=(--skip-browser)
fi
if [[ "$INCLUDE_DESKTOP" == "true" ]]; then
    args+=(--include-desktop)
fi

echo "安装 Hermes Agent ${HERMES_AGENT_TAG}..."
bash "$installer" "${args[@]}"

echo ""
echo "Hermes Agent 安装完成"
if command -v hermes &>/dev/null; then
    hermes --version || true
else
    echo "请重新加载 shell 后使用 hermes，或确认 ~/.local/bin 在 PATH 中"
fi
