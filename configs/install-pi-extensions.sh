#!/bin/bash
# 更新 Pi Agent 全局扩展 packages（列表以 ~/.pi/agent/settings.json 的 packages 为准，
# pi 启动时会自动安装缺失的 packages），并安装本仓库的自定义扩展到 ~/.pi/agent

set -euo pipefail

USE_CN=false
NPM_REGISTRY=""

usage() {
    cat << EOF
用法: $0 [-cn] [--registry URL]

按 settings.json 的 packages 更新 Pi extensions 到最新，并安装本仓库的自定义扩展。

选项:
  -cn             使用 npmmirror npm registry
  --registry URL  使用指定 npm registry
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
            ;;
        --registry)
            if [[ $# -lt 2 ]]; then
                usage
                exit 1
            fi
            NPM_REGISTRY="$2"
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ "$USE_CN" == "true" && -z "$NPM_REGISTRY" ]]; then
    NPM_REGISTRY="https://registry.npmmirror.com"
fi

if ! command -v pi &>/dev/null; then
    echo "错误: 缺少 pi 命令，可先运行 ./install/install-pi-agent.sh"
    exit 1
fi

if [[ -n "$NPM_REGISTRY" ]]; then
    export npm_config_registry="$NPM_REGISTRY"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "按 settings.json 更新 Pi packages 到最新..."
pi update --extensions

bash "$SCRIPT_DIR/pi/extensions/install-extensions.sh"

echo "Pi extensions 已安装。Pi 中使用 /reload 后生效；也可以重启 pi。"
