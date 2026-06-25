#!/bin/bash
# 安装 Oh My Bash，并确保 bashrc 加载 ~/.config/env.d/*.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

OH_MY_BASH_URL="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"
OH_MY_BASH_DIR="$HOME/.oh-my-bash"
BASHRC="$HOME/.bashrc"
ENV_DIR="$HOME/.config/env.d"
THEME="purity"
BEGIN_MARKER="# BEGIN configs bashrc"
END_MARKER="# END configs bashrc"

if [[ -d "$OH_MY_BASH_DIR" ]]; then
    echo "Oh My Bash 已安装: $OH_MY_BASH_DIR"
else
    echo "安装 Oh My Bash..."
    bash -c "$(curl -fsSL "$(configs_github_url "$OH_MY_BASH_URL")")"
fi

if [[ ! -f "$BASHRC" ]]; then
    touch "$BASHRC"
fi

mkdir -p "$ENV_DIR"

MANAGED_BLOCK="$(mktemp)"
TMP_BASHRC="$(mktemp)"
trap 'rm -f "$MANAGED_BLOCK" "$TMP_BASHRC"' EXIT

{
    echo "$BEGIN_MARKER"
    echo "OSH_THEME=\"$THEME\""
    echo ""
    echo "# 加载环境变量配置"
    echo 'for env_file in "$HOME/.config/env.d"/*.sh; do'
    echo '    [ -f "$env_file" ] || continue'
    echo '    source "$env_file"'
    echo 'done'
    echo ""
    echo "# 配置 PATH"
    echo 'case ":$PATH:" in'
    echo '    *":$HOME/.local/bin:"*) ;;'
    echo '    *) export PATH="$HOME/.local/bin:$PATH" ;;'
    echo 'esac'
    echo "$END_MARKER"
} > "$MANAGED_BLOCK"

HAS_BEGIN=0
HAS_END=0
grep -qF "$BEGIN_MARKER" "$BASHRC" && HAS_BEGIN=1
grep -qF "$END_MARKER" "$BASHRC" && HAS_END=1

if [[ "$HAS_BEGIN" -ne "$HAS_END" ]]; then
    echo "错误: $BASHRC 中存在不完整的 configs managed block"
    exit 1
elif [[ "$HAS_BEGIN" -eq 1 ]]; then
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
    ' "$BASHRC" > "$TMP_BASHRC"
elif grep -q 'oh-my-bash\.sh' "$BASHRC"; then
    awk -v block="$MANAGED_BLOCK" '
        BEGIN {
            while ((getline line < block) > 0) {
                replacement = replacement line ORS
            }
        }
        !inserted && /oh-my-bash\.sh/ {
            printf "%s", replacement
            inserted = 1
        }
        { print }
    ' "$BASHRC" > "$TMP_BASHRC"
elif [[ -s "$BASHRC" ]]; then
    cp "$BASHRC" "$TMP_BASHRC"
    echo "" >> "$TMP_BASHRC"
    cat "$MANAGED_BLOCK" >> "$TMP_BASHRC"
else
    cp "$MANAGED_BLOCK" "$TMP_BASHRC"
fi

mv "$TMP_BASHRC" "$BASHRC"
echo ".bashrc managed block 已更新"

echo "Oh My Bash 配置完成"
echo "  theme: $THEME"
