#!/bin/bash
# 安装 Oh My Bash，并确保 bashrc 加载 ~/.config/env.d/*.sh

set -e

OH_MY_BASH_URL="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"
OH_MY_BASH_DIR="$HOME/.oh-my-bash"
BASHRC="$HOME/.bashrc"
ENV_DIR="$HOME/.config/env.d"
LOADER_LINE='for env_file in "$HOME/.config/env.d"/*.sh; do'
OLD_LOADER_SOURCE='    [ -f "$env_file" ] && source "$env_file"'
THEME="purity"

if [[ -d "$OH_MY_BASH_DIR" ]]; then
    echo "Oh My Bash 已安装: $OH_MY_BASH_DIR"
else
    echo "安装 Oh My Bash..."
    bash -c "$(curl -fsSL "$OH_MY_BASH_URL")"
fi

if [[ ! -f "$BASHRC" ]]; then
    touch "$BASHRC"
fi

if grep -q '^OSH_THEME=' "$BASHRC"; then
    sed -i "s/^OSH_THEME=.*/OSH_THEME=\"$THEME\"/" "$BASHRC"
elif grep -q 'oh-my-bash.sh' "$BASHRC"; then
    sed -i "/oh-my-bash\.sh/i OSH_THEME=\"$THEME\"" "$BASHRC"
else
    echo "OSH_THEME=\"$THEME\"" >> "$BASHRC"
fi

if grep -qF "$LOADER_LINE" "$BASHRC" 2>/dev/null; then
    echo "env.d 加载逻辑已存在于 .bashrc"
    if grep -qF "$OLD_LOADER_SOURCE" "$BASHRC" 2>/dev/null; then
        sed -i 's@    \[ -f "$env_file" \] && source "$env_file"@    [ -f "$env_file" ] || continue\n    source "$env_file"@' "$BASHRC"
        echo "已更新 env.d 加载逻辑"
    fi
else
    mkdir -p "$ENV_DIR"

    echo "" >> "$BASHRC"
    echo "# 加载环境变量配置" >> "$BASHRC"
    echo 'for env_file in "$HOME/.config/env.d"/*.sh; do' >> "$BASHRC"
    echo '    [ -f "$env_file" ] || continue' >> "$BASHRC"
    echo '    source "$env_file"' >> "$BASHRC"
    echo 'done' >> "$BASHRC"

    echo "已添加 env.d 加载逻辑到 .bashrc"
fi

# 配置 PATH
if ! grep -q '\.local/bin' "$BASHRC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
    echo "已添加 ~/.local/bin 到 PATH"
fi

echo "Oh My Bash 配置完成"
echo "  theme: $THEME"
