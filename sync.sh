#!/bin/bash
# 将机器上的配置同步到代码库

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sync_nvim() {
    local source="$HOME/.config/nvim/init.lua"
    local dest="$SCRIPT_DIR/configs/nvim/init.lua"

    if [[ ! -f "$source" ]]; then
        echo "错误: 源文件不存在: $source"
        exit 1
    fi

    cp "$source" "$dest"
    echo "已同步: $source -> $dest"
}

sync_pj() {
    local pj_source="$HOME/pj.sh"
    local template_source="$HOME/pj.env.sh"
    local pj_dest="$SCRIPT_DIR/tools/pj/pj.sh"
    local template_dest="$SCRIPT_DIR/tools/pj/pj.env.sh"

    if [[ ! -f "$pj_source" ]]; then
        echo "错误: 源文件不存在: $pj_source"
        exit 1
    fi

    cp "$pj_source" "$pj_dest"
    echo "已同步: $pj_source -> $pj_dest"

    if [[ -f "$template_source" ]]; then
        cp "$template_source" "$template_dest"
        echo "已同步: $template_source -> $template_dest"
    fi
}

usage() {
    cat << 'EOF'
用法: sync.sh <target>

目标:
    nvim    同步 nvim 配置
    pj      同步 pj 环境切换器
EOF
}

case "${1:-}" in
    nvim)
        sync_nvim
        ;;
    pj)
        sync_pj
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
echo "同步完成!"