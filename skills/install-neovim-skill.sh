#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/lengmoXXL/neovim-skill.git}"
REF="${REF:-master}"
SKILL_PATH="${SKILL_PATH:-skills/neovim-skill}"
DEST_ROOT="${AGENTS_HOME:-$HOME/.agents}/skills"
DEST="$DEST_ROOT/neovim-skill"
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

echo "Cloning $REPO_URL..."
git clone --filter=blob:none --sparse --depth 1 --branch "$REF" "$REPO_URL" "$TMP_DIR/repo"

echo "Checking out $SKILL_PATH..."
git -C "$TMP_DIR/repo" sparse-checkout set "$SKILL_PATH"

SRC="$TMP_DIR/repo/$SKILL_PATH"
if [[ ! -f "$SRC/SKILL.md" ]]; then
    echo "Missing skill source: $SRC" >&2
    exit 1
fi

mkdir -p "$DEST_ROOT"
rm -rf "$DEST"
cp -a "$SRC" "$DEST"

echo "Installed neovim-skill to $DEST"
echo "Restart your agent to pick up new skills."
