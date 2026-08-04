#!/bin/bash
# 下载 Nerd Fonts 字体

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_DIR="$SCRIPT_DIR/../fonts"
USE_CN=false
GITHUB_RELEASE_PROXY="https://gh-proxy.com/"

github_release_url() {
    local url="$1"

    if [[ "$USE_CN" == "true" ]]; then
        echo "${GITHUB_RELEASE_PROXY}${url}"
    else
        echo "$url"
    fi
}

get_font_info() {
    case "$1" in
        sarasa)
            echo "Sarasa Term SC Nerd|$(github_release_url "https://github.com/laishulu/Sarasa-Term-SC-Nerd/releases/download/v2.3.1/SarasaTermSCNerd.ttf.tar.gz")|tar.gz"
            ;;
        aurulent)
            echo "AurulentSansMono Nerd Font|$(github_release_url "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/AurulentSansMono.zip")|zip"
            ;;
        droid)
            echo "DroidSansMono Nerd Font|$(github_release_url "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/DroidSansMono.zip")|zip"
            ;;
        *)
            return 1
            ;;
    esac
}

list_fonts() {
    echo "可用字体:"
    echo "  sarasa   - Sarasa Term SC Nerd"
    echo "  aurulent - AurulentSansMono Nerd Font"
    echo "  droid    - DroidSansMono Nerd Font"
}

download_font() {
    local name="$1"
    local info

    case "$name" in
        droidsansmono | DroidSansMono) name="droid" ;;
    esac

    if ! info=$(get_font_info "$name"); then
        echo "错误: 未知字体 '$name'"
        list_fonts
        return 1
    fi

    local display_name url format
    display_name=$(echo "$info" | cut -d'|' -f1)
    url=$(echo "$info" | cut -d'|' -f2)
    format=$(echo "$info" | cut -d'|' -f3)

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
    echo "用法: $0 [-cn] [字体名...]"
    echo ""
    list_fonts
    echo ""
    echo "选项:"
    echo "  -cn      通过国内代理下载 GitHub Release 文件"
    echo ""
    echo "不带参数则安装全部字体"
}

mkdir -p "$FONTS_DIR"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

FONT_NAMES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            FONT_NAMES+=("$1")
            ;;
    esac
    shift
done

if [[ ${#FONT_NAMES[@]} -eq 0 ]]; then
    # 安装全部
    echo "安装全部字体..."
    download_font "sarasa"
    download_font "aurulent"
    download_font "droid"
else
    # 安装指定的字体
    for name in "${FONT_NAMES[@]}"; do
        download_font "$name"
    done
fi

echo ""
echo "字体已安装到: $FONTS_DIR"
