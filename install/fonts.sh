#!/bin/bash
# 从 OSS 下载字体到 fonts/ 目录
# 可重入：重复执行覆盖同名文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_DIR="$SCRIPT_DIR/../fonts"
OSS_BASE_URL="https://lengmo-asserts.oss-cn-beijing.aliyuncs.com/fonts"

# 每个字体对应的 OSS 文件清单（URL 编码形式）
font_files() {
    case "$1" in
        dejavu)
            # Regular + Bold，主字体
            echo "DejaVuSansMNerdFontMono-Regular.ttf DejaVuSansMNerdFontMono-Bold.ttf"
            ;;
        aurulent)
            echo "AurulentSansMNerdFont-Regular.otf AurulentSansMNerdFontMono-Regular.otf AurulentSansMNerdFontPropo-Regular.otf README.md SIL%20Open%20Font%20License.txt"
            ;;
        droid)
            # 打过补丁的版本：补了 U+25CB ○ 字形（herdr idle 符号）
            echo "DroidSansMNerdFontMono-Regular.ttf"
            ;;
        yunhei)
            # 打过补丁的版本：声明等宽并规范家族名为 TsangerYunHei（Ghostty 只收等宽字体）
            echo "%E4%BB%93%E8%80%B3%E4%BA%91%E9%BB%91-W04.ttf %E4%BB%93%E8%80%B3%E4%BA%91%E9%BB%91-W07.ttf"
            ;;
        *)
            return 1
            ;;
    esac
}

list_fonts() {
    echo "可用字体:"
    echo "  aurulent - AurulentSansMono Nerd Font"
    echo "  droid    - DroidSansMono Nerd Font（含 ○ 补丁）"
    echo "  dejavu   - DejaVuSansMono Nerd Font Regular+Bold（主字体）"
    echo "  yunhei   - TsangerYunHei W04 (仓耳云黑，等宽补丁)"
}

download_font() {
    local name="$1" files
    if ! files=$(font_files "$name"); then
        echo "错误: 未知字体 '$name'"
        list_fonts
        return 1
    fi

    local font_dir="$FONTS_DIR/$name"
    mkdir -p "$font_dir"

    local encoded filename
    for encoded in $files; do
        # 还原 URL 编码的文件名（空格、中文等）
        filename=$(printf '%b' "${encoded//%/\\x}")
        echo "下载 $name/$filename ..."
        curl -fL "$OSS_BASE_URL/$name/$encoded" -o "$font_dir/$filename"
    done
}

usage() {
    echo "用法: $0 [字体名...]"
    echo ""
    list_fonts
    echo ""
    echo "不带参数则安装全部字体"
}

FONT_NAMES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
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

if [[ "${UPDATE:-}" == "1" ]]; then
    echo "跳过字体更新（未固定版本）"
    exit 0
fi

if [[ ${#FONT_NAMES[@]} -eq 0 ]]; then
    echo "安装全部字体..."
    FONT_NAMES=(dejavu aurulent droid yunhei)
fi

for name in "${FONT_NAMES[@]}"; do
    download_font "$name"
done

echo ""
