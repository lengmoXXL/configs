#!/usr/bin/env bash
# 安装 doc-research skill：克隆仓库到 skill 目录（根目录即 skill，含 pyproject，可直接 uv tool install）
# PINNED_COMMIT 固定安装版本；运行时对比远端 HEAD，不一致则提示有更新（需人工更新此常量后重跑）
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/lengmoXXL/doc-research.git}"
PINNED_COMMIT="9fadb93a34902bdf902262ced1155ee698ed050b"
DEST_ROOT="${AGENTS_HOME:-$HOME/.agents}/skills"
DEST="$DEST_ROOT/doc-research"
TMP_DIR="$(mktemp -d)"
USE_CN=false
GITHUB_PROXY_PREFIX="https://gh-proxy.com/"

trap 'rm -rf "$TMP_DIR"' EXIT

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

if [[ "$USE_CN" == "true" && "$REPO_URL" == https://github.com/* ]]; then
    REPO_URL="${GITHUB_PROXY_PREFIX}${REPO_URL}"
fi

remote_head="$(git ls-remote "$REPO_URL" HEAD | awk '{print $1}')"
if [[ -z "$remote_head" ]]; then
    echo "错误: 无法获取远端 HEAD: $REPO_URL" >&2
    exit 1
fi
if [[ "$remote_head" != "$PINNED_COMMIT" ]]; then
    echo "提示: 远端有新提交 $remote_head（当前固定 $PINNED_COMMIT），确认后更新 PINNED_COMMIT 再装"
fi

git clone --quiet "$REPO_URL" "$TMP_DIR/repo"
git -C "$TMP_DIR/repo" checkout --quiet "$PINNED_COMMIT"

if [[ ! -f "$TMP_DIR/repo/SKILL.md" ]]; then
    echo "Missing skill source: $TMP_DIR/repo/SKILL.md" >&2
    exit 1
fi

mkdir -p "$DEST_ROOT"
rm -rf "$DEST"
cp -a "$TMP_DIR/repo" "$DEST"
rm -rf "$DEST/.git"

# 安装/更新 CLI（--force 保证已安装时也刷新到新版本）
if ! command -v uv &>/dev/null; then
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    echo "错误: 缺少 uv，请先运行 $repo_root/install/install-uv.sh" >&2
    exit 1
fi
uv tool install --force --python 3.11 "$DEST"

echo "Installed doc-research skill + CLI ($PINNED_COMMIT) to $DEST"
echo "Restart your agent to pick up new skills."
