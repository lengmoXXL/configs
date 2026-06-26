#!/bin/bash
# 安装 tmux 配置到 ~/.tmux.conf
# 可重入：重复执行会覆盖旧配置

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SOURCE="$SCRIPT_DIR/tmux/tmux.conf"
TMUX_DEST="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"
TPM_REPO="https://github.com/tmux-plugins/tpm.git"
USE_CN=false
GITHUB_PROXY_PREFIX="https://gh-proxy.com/"

usage() {
    cat << EOF
用法: $0 [-cn]

选项:
  -cn      通过国内代理 clone GitHub 仓库
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

if [[ "$USE_CN" == "true" ]]; then
    TPM_REPO="${GITHUB_PROXY_PREFIX}${TPM_REPO}"
fi

if [[ ! -f "$TMUX_SOURCE" ]]; then
    echo "错误: 源配置不存在: $TMUX_SOURCE"
    exit 1
fi

if ! command -v git &>/dev/null; then
    echo "错误: 缺少依赖 git"
    exit 1
fi

if [[ -d "$TPM_DIR/.git" ]]; then
    echo "更新 TPM: $TPM_DIR"
    git -C "$TPM_DIR" remote set-url origin "$TPM_REPO"
    git -C "$TPM_DIR" pull --ff-only
elif [[ ! -e "$TPM_DIR" ]]; then
    echo "安装 TPM: $TPM_DIR"
    git clone --depth 1 "$TPM_REPO" "$TPM_DIR"
else
    echo "错误: TPM 目录已存在但不是 git 仓库: $TPM_DIR"
    exit 1
fi

cp "$TMUX_SOURCE" "$TMUX_DEST"
echo "tmux 配置已安装: $TMUX_DEST"
