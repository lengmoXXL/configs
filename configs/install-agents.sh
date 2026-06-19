#!/bin/bash
# 安装/更新 AGENTS.md 规则（支持 codex / opencode）
# 组合 common 通用提示词与指定模式的专属提示词，写入对应工具的全局规则文件
# 可重入：重复执行会替换 managed block，保留块外其它内容

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="${PROMPTS_DIR:-$SCRIPT_DIR/agents}"
COMMON_PROMPT="$PROMPTS_DIR/common.md"

usage() {
    cat <<EOF
用法: $(basename "$0") <mode>

组合 common 与指定模式的提示词，写入对应工具的全局 AGENTS.md。

参数:
  mode    目标工具: codex | opencode

环境变量:
  CODEX_AGENTS_DEST      Codex 目标文件 (默认 ~/.codex/AGENTS.md)
  OPENCODE_AGENTS_DEST   OpenCode 目标文件 (默认 ~/.config/opencode/AGENTS.md)
  PROMPTS_DIR            提示词源目录 (默认 <脚本目录>/agents)
EOF
}

mode="${1:-}"
if [[ -z "$mode" ]]; then
    usage >&2
    exit 1
fi

case "$mode" in
    codex)
        mode_prompt="$PROMPTS_DIR/codex.md"
        dest="${CODEX_AGENTS_DEST:-$HOME/.codex/AGENTS.md}"
        begin_marker="<!-- BEGIN configs codex AGENTS -->"
        end_marker="<!-- END configs codex AGENTS -->"
        ;;
    opencode)
        mode_prompt="$PROMPTS_DIR/opencode.md"
        dest="${OPENCODE_AGENTS_DEST:-$HOME/.config/opencode/AGENTS.md}"
        begin_marker="<!-- BEGIN configs opencode AGENTS -->"
        end_marker="<!-- END configs opencode AGENTS -->"
        ;;
    *)
        echo "错误: 未知模式 '$mode' (支持: codex, opencode)" >&2
        usage >&2
        exit 1
        ;;
esac

for f in "$COMMON_PROMPT" "$mode_prompt"; do
    if [[ ! -f "$f" ]]; then
        echo "错误: 缺少提示词文件: $f" >&2
        exit 1
    fi
done

mode_content="$(cat "$mode_prompt")"
common_content="$(cat "$COMMON_PROMPT")"

mkdir -p "$(dirname "$dest")"

MANAGED_BLOCK="$(mktemp)"
TMP_DEST="$(mktemp)"
trap 'rm -f "$MANAGED_BLOCK" "$TMP_DEST"' EXIT

{
    echo "$begin_marker"
    printf '%s\n\n' "$mode_content"
    printf '%s\n' "$common_content"
    echo "$end_marker"
} > "$MANAGED_BLOCK"

if [[ -f "$dest" ]] && grep -qF "$begin_marker" "$dest" && grep -qF "$end_marker" "$dest"; then
    awk -v begin="$begin_marker" -v end="$end_marker" -v block="$MANAGED_BLOCK" '
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
    ' "$dest" > "$TMP_DEST"
elif [[ -f "$dest" && -s "$dest" ]]; then
    cp "$dest" "$TMP_DEST"
    echo "" >> "$TMP_DEST"
    cat "$MANAGED_BLOCK" >> "$TMP_DEST"
else
    cp "$MANAGED_BLOCK" "$TMP_DEST"
fi

mv "$TMP_DEST" "$dest"
echo "AGENTS.md 已更新 ($mode): $dest"
