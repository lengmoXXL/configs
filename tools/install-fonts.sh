#!/bin/bash
# 下载 Nerd Fonts 字体

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_DIR="$SCRIPT_DIR/../fonts"
PROXY="${GITHUB_PROXY:-https://gh-proxy.com/}"

# 字体列表
declare -A FONTS=(
    ["sarasa"]="Sarasa Term SC Nerd|${PROXY}https://github.com/laishulu/Sarasa-Term-SC-Nerd/releases/download/v2.3.1/SarasaTermSCNerd.ttf.tar.gz|tar.gz"
    ["aurulent"]="AurulentSansMono Nerd Font|${PROXY}https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AurulentSansMono.zip|zip"
)

download_font() {
    local name="$1"
    local info="${FONTS[$name]}"

    if [[ -z "$info" ]]; then
        echo "错误: 未知字体 '$name'"
        echo "可用字体: ${!FONTS[*]}"
        return 1
    fi

    local display_name url format
    IFS='|' read -r display_name url format <<< "$info"

    echo "下载 $display_name ..."

    local tmp_file="$TMPDIR/font.$format"
    curl -fL "$url" -o "$tmp_file"

    local font_dir="$FONTS_DIR/$name"
    mkdir -p "$font_dir"

    case "$format" in
        tar.gz)
            tar -xzf "$tmp_file" -C "$font_dir"
            ;;
        zip)
            unzip -o "$tmp_file" -d "$font_dir" >/dev/null
            ;;
    esac

    echo "  -> $font_dir"
}

usage() {
    echo "用法: $0 [字体名...]"
    echo ""
    echo "可用字体:"
    for name in "${!FONTS[@]}"; do
        IFS='|' read -r display_name _ _ <<< "${FONTS[$name]}"
        echo "  $name  - $display_name"
    done
    echo ""
    echo "不带参数则安装全部字体"
}

mkdir -p "$FONTS_DIR"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

if [[ $# -eq 0 ]]; then
    # 安装全部
    echo "安装全部字体..."
    for name in "${!FONTS[@]}"; do
        download_font "$name"
    done
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
else
    # 安装指定的字体
    for name in "$@"; do
        download_font "$name"
    done
fi

echo ""
echo "字体已安装到: $FONTS_DIR"