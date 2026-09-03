#!/bin/bash
# 一键初始化：--init 基础配置，其余为场景（需先 --init）

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_MARKER="$HOME/.local/share/configs-setup/initialized"
USE_CN=false
MODE="init"

usage() {
    cat << EOF
用法: $0 [-cn] [--init | --nvim]

选项:
  -cn      子脚本使用国内代理/镜像

模式:
  --init   基础配置: secrets、shell 环境（env.d）、pi agent（含配置与 extensions）、系统配置（默认）
  --nvim   编辑场景: Neovim + 配置（需先 --init）
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        --init)
            MODE="init"
            ;;
        --nvim)
            MODE="nvim"
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
    shift
done

cn_args=()
if [[ "$USE_CN" == "true" ]]; then
    cn_args=(-cn)
fi

run() {
    echo ""
    echo "==> $*"
    "$@"
}

install_ghostty_macos() {
    if [[ -d "/Applications/Ghostty.app" ]]; then
        echo "Ghostty 已安装"
        return
    fi

    echo "Ghostty 未安装，打开下载页面，请手动下载并安装到 /Applications"
    open "https://ghostty.org/download"
    read -rp "安装完成后按回车继续... "
    if [[ ! -d "/Applications/Ghostty.app" ]]; then
        echo "错误: 未检测到 /Applications/Ghostty.app" >&2
        exit 1
    fi
}

case "$MODE" in
    init)
        # 基础配置: secrets、shell 环境（env.d）、pi agent
        run "$ROOT/tools/secrets.sh" init
        if [[ "$(uname -s)" == "Darwin" ]]; then
            run "$ROOT/install/oh-my-zsh.sh" "${cn_args[@]}"
        else
            run "$ROOT/install/oh-my-bash.sh" "${cn_args[@]}"
        fi
        run "$ROOT/install/pi-agent.sh" "${cn_args[@]}"
        run python3 "$ROOT/install/pi-config.py"
        run "$ROOT/install/pi-extensions.sh"

        # 系统配置
        if [[ "$(uname -s)" == "Darwin" ]]; then
            run "$ROOT/install/fonts.sh"
            install_ghostty_macos
            run "$ROOT/install/ghostty-config.sh"
        else
            run "$ROOT/install/ghostty-terminfo.sh"
        fi

        mkdir -p "$(dirname "$INIT_MARKER")"
        touch "$INIT_MARKER"
        ;;
    nvim)
        if [[ ! -f "$INIT_MARKER" ]]; then
            echo "错误: 尚未初始化，请先运行 $0 --init" >&2
            exit 1
        fi
        run "$ROOT/install/nvim.sh" "${cn_args[@]}"
        run "$ROOT/install/nvim-config.sh"
        ;;
esac

echo ""
echo "setup 完成（$MODE）"
