#!/bin/bash
# 更新 Codex AGENTS.md 规则
# 可重入：重复执行会替换 managed block，保留其它内容

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_SOURCE="$SCRIPT_DIR/codex/AGENTS.md"
CODEX_DEST="${CODEX_AGENTS_DEST:-$HOME/.codex/AGENTS.md}"
BEGIN_MARKER="<!-- BEGIN configs codex AGENTS -->"
END_MARKER="<!-- END configs codex AGENTS -->"

if [[ ! -f "$CODEX_SOURCE" ]]; then
    echo "错误: 源配置不存在: $CODEX_SOURCE"
    exit 1
fi

mkdir -p "$(dirname "$CODEX_DEST")"

MANAGED_BLOCK="$(mktemp)"
TMP_DEST="$(mktemp)"
trap 'rm -f "$MANAGED_BLOCK" "$TMP_DEST"' EXIT

{
    echo "$BEGIN_MARKER"
    cat "$CODEX_SOURCE"
    echo "$END_MARKER"
} > "$MANAGED_BLOCK"

if [[ -f "$CODEX_DEST" ]] && grep -qF "$BEGIN_MARKER" "$CODEX_DEST" && grep -qF "$END_MARKER" "$CODEX_DEST"; then
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v block="$MANAGED_BLOCK" '
        BEGIN {
            while ((getline line < block) > 0) {
                replacement = replacement line ORS
            }
        }
        $0 == begin {
            printf "%s", replacement
            in_block = 1
            next
        }
        $0 == end {
            in_block = 0
            next
        }
        !in_block {
            print
        }
    ' "$CODEX_DEST" > "$TMP_DEST"
elif [[ -f "$CODEX_DEST" && -s "$CODEX_DEST" ]]; then
    cp "$CODEX_DEST" "$TMP_DEST"
    echo "" >> "$TMP_DEST"
    cat "$MANAGED_BLOCK" >> "$TMP_DEST"
else
    cp "$MANAGED_BLOCK" "$TMP_DEST"
fi

mv "$TMP_DEST" "$CODEX_DEST"
echo "Codex AGENTS.md 已更新: $CODEX_DEST"
