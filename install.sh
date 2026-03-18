#!/bin/bash
# 将代码库的配置更新到机器上

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

install_nvim() {
    local source_dir="$SCRIPT_DIR/configs/nvim"
    local dest_dir="$HOME/.config/nvim"

    if [[ ! -d "$source_dir" ]]; then
        echo "错误: 源目录不存在: $source_dir"
        exit 1
    fi

    mkdir -p "$dest_dir"
    cp -r "$source_dir"/* "$dest_dir/"
    echo "已安装: $source_dir -> $dest_dir"
}

install_pj() {
    # 检查 fzf 依赖
    if ! command -v fzf &>/dev/null; then
        echo "错误: fzf 未安装，请先安装 fzf"
        exit 1
    fi

    local pj_source="$SCRIPT_DIR/tools/pj/pj.sh"
    local template_source="$SCRIPT_DIR/tools/pj/pj.env.sh"
    local pj_dest="$HOME/pj.sh"
    local template_dest="$HOME/pj.env.sh"

    if [[ ! -f "$pj_source" ]]; then
        echo "错误: 源文件不存在: $pj_source"
        exit 1
    fi

    mkdir -p "$HOME/.pjs"

    cp "$pj_source" "$pj_dest"
    echo "已安装: $pj_source -> $pj_dest"

    if [[ -f "$template_source" ]]; then
        cp "$template_source" "$template_dest"
        echo "已安装: $template_source -> $template_dest"
    fi

    local bashrc="$HOME/.bashrc"
    if ! grep -qF 'source "$HOME/pj.sh"' "$bashrc" 2>/dev/null; then
        echo "" >> "$bashrc"
        echo '[ -f "$HOME/pj.sh" ] && source "$HOME/pj.sh"' >> "$bashrc"
        echo "已添加 pj 到 .bashrc"
    else
        echo "pj 已存在于 .bashrc"
    fi
}

usage() {
    cat << 'EOF'
用法: install.sh <target>

目标:
    nvim    安装 nvim 配置
    pj      安装 pj 环境切换器
EOF
}

case "${1:-}" in
    nvim)
        install_nvim
        ;;
    pj)
        install_pj
        ;;
    -h|--help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac

echo ""
echo "安装完成!"