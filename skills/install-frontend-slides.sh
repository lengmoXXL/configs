#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/zarazhangrui/frontend-slides.git}"
REF="${REF:-main}"
SKILL_PATH="${SKILL_PATH:-plugins/frontend-slides/skills/frontend-slides}"
DEST_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
DEST="$DEST_ROOT/frontend-slides"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v git &>/dev/null; then
    echo "Missing dependency: git" >&2
    exit 1
fi

export GIT_TERMINAL_PROMPT=0

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

echo "Installed frontend-slides to $DEST"
echo "Restart Codex to pick up new skills."
