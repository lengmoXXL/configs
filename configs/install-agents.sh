#!/bin/bash
# 一次性安装/更新所有工具的 AGENTS.md 规则（codex / opencode）
# 为每个工具组合 common 通用提示词与该工具的专属提示词，写入对应全局规则文件
# 无需参数；可重入：重复执行会替换 managed block，保留块外其它内容

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="${PROMPTS_DIR:-$SCRIPT_DIR/agents}"
COMMON_PROMPT="$PROMPTS_DIR/common.md"

if [[ ! -f "$COMMON_PROMPT" ]]; then
    echo "错误: 缺少通用提示词文件: $COMMON_PROMPT" >&2
    exit 1
fi

common_content="$(cat "$COMMON_PROMPT")"

install_mode() {
    local mode="$1" mode_prompt="$2" dest="$3" begin_marker="$4" end_marker="$5"

    if [[ ! -f "$mode_prompt" ]]; then
        echo "错误: 缺少提示词文件: $mode_prompt" >&2
        return 1
    fi

    local mode_content managed_block tmp_dest
    mode_content="$(cat "$mode_prompt")"
    managed_block="$(mktemp)"
    tmp_dest="$(mktemp)"
    trap 'rm -f "$managed_block" "$tmp_dest"' RETURN

    mkdir -p "$(dirname "$dest")"

    {
        echo "$begin_marker"
        printf '%s\n\n' "$mode_content"
        printf '%s\n' "$common_content"
        echo "$end_marker"
    } > "$managed_block"

    if [[ -f "$dest" ]] && grep -qF "$begin_marker" "$dest" && grep -qF "$end_marker" "$dest"; then
        awk -v begin="$begin_marker" -v end="$end_marker" -v block="$managed_block" '
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
        ' "$dest" > "$tmp_dest"
    elif [[ -f "$dest" && -s "$dest" ]]; then
        cp "$dest" "$tmp_dest"
        echo "" >> "$tmp_dest"
        cat "$managed_block" >> "$tmp_dest"
    else
        cp "$managed_block" "$tmp_dest"
    fi

    mv "$tmp_dest" "$dest"
    echo "AGENTS.md 已更新 ($mode): $dest"
}

install_mode codex \
    "$PROMPTS_DIR/codex.md" \
    "${CODEX_AGENTS_DEST:-$HOME/.codex/AGENTS.md}" \
    "<!-- BEGIN configs codex AGENTS -->" \
    "<!-- END configs codex AGENTS -->"

install_mode opencode \
    "$PROMPTS_DIR/opencode.md" \
    "${OPENCODE_AGENTS_DEST:-$HOME/.config/opencode/AGENTS.md}" \
    "<!-- BEGIN configs opencode AGENTS -->" \
    "<!-- END configs opencode AGENTS -->"
