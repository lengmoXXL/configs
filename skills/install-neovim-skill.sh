#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root/install/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

REPO_URL="${REPO_URL:-https://github.com/lengmoXXL/neovim-skill.git}"
REF="${REF:-master}"
SKILL_PATH="${SKILL_PATH:-skills/neovim-skill}"
DEST_ROOT="${AGENTS_HOME:-$HOME/.agents}/skills"
DEST="$DEST_ROOT/neovim-skill"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

echo "Cloning $REPO_URL..."
configs_git clone --filter=blob:none --sparse --depth 1 --branch "$REF" "$REPO_URL" "$TMP_DIR/repo"

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
