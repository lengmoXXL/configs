#!/bin/bash
# 确保 bashrc 加载 ~/.config/env.d/*.sh

set -e

BASHRC="$HOME/.bashrc"
ENV_DIR="$HOME/.config/env.d"
LOADER_LINE='for env_file in "$HOME/.config/env.d"/*.sh; do'

if grep -qF "$LOADER_LINE" "$BASHRC" 2>/dev/null; then
    echo "env.d 加载逻辑已存在于 .bashrc"
    exit 0
fi

mkdir -p "$ENV_DIR"

echo "" >> "$BASHRC"
echo "# 加载环境变量配置" >> "$BASHRC"
echo 'for env_file in "$HOME/.config/env.d"/*.sh; do' >> "$BASHRC"
echo '    [ -f "$env_file" ] && source "$env_file"' >> "$BASHRC"
echo 'done' >> "$BASHRC"

echo "已添加 env.d 加载逻辑到 .bashrc"