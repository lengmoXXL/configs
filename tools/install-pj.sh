#!/bin/bash
# 安装 pj 仓库命令工具到 ~/.config/env.d
# 可重入：重复执行会更新托管文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$HOME/.config/env.d"

# 检查 fzf 依赖
if ! command -v fzf &>/dev/null; then
    echo "错误: fzf 未安装，请先运行 install/install-basic-tools.sh"
    exit 1
fi

# 确保 env.d 遍历逻辑存在于 bashrc
ensure_envd_loader() {
    local bashrc="$HOME/.bashrc"
    local loader_line='for env_file in "$HOME/.config/env.d"/*.sh; do'

    if ! grep -qF "$loader_line" "$bashrc" 2>/dev/null; then
        mkdir -p "$ENV_DIR"
        echo "" >> "$bashrc"
        echo "# 加载环境变量配置" >> "$bashrc"
        echo 'for env_file in "$HOME/.config/env.d"/*.sh; do' >> "$bashrc"
        echo '    [ -f "$env_file" ] && source "$env_file"' >> "$bashrc"
        echo 'done' >> "$bashrc"
        echo "已添加 env.d 加载逻辑到 .bashrc"
    else
        echo "env.d 加载逻辑已存在于 .bashrc"
    fi
}

# 确保 env.d 加载逻辑存在
ensure_envd_loader

pj_source="$SCRIPT_DIR/pj/pj.sh"
pj_dest="$ENV_DIR/pj.sh"

if [[ ! -f "$pj_source" ]]; then
    echo "错误: 源文件不存在: $pj_source"
    exit 1
fi

mkdir -p "$HOME/.pjs"
mkdir -p "$ENV_DIR"

cp "$pj_source" "$pj_dest"
echo "已安装: $pj_source -> $pj_dest"

echo ""
echo "pj 安装完成"
echo "请运行 'source ~/.bashrc' 使配置生效"
