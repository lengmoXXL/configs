#!/bin/bash
# 安装 Pi Agent 全局扩展 packages 到 ~/.pi/agent

set -euo pipefail

PLAN_MODE_PACKAGE="@narumitw/pi-plan-mode"
PLAN_MODE_VERSION="0.44.0"
PLAN_MODE_SOURCE="npm:${PLAN_MODE_PACKAGE}@${PLAN_MODE_VERSION}"
SIMPLIFY_PACKAGE="pi-simplify"
SIMPLIFY_VERSION="0.2.3"
SIMPLIFY_SOURCE="npm:${SIMPLIFY_PACKAGE}@${SIMPLIFY_VERSION}"
SUBAGENTS_REPO="github.com/nicobailon/pi-subagents"
SUBAGENTS_VERSION="v0.40.0"
SUBAGENTS_SOURCE="git:${SUBAGENTS_REPO}@${SUBAGENTS_VERSION}"
HASHLINE_PACKAGE="pi-hashline-edit-pro"
HASHLINE_VERSION="0.20.0"
HASHLINE_SOURCE="npm:${HASHLINE_PACKAGE}@${HASHLINE_VERSION}"
FOOTER_PACKAGE="pi-footer"
FOOTER_VERSION="0.5.1"
FOOTER_SOURCE="npm:${FOOTER_PACKAGE}@${FOOTER_VERSION}"
USE_CN=false
NPM_REGISTRY=""

usage() {
    cat << EOF
用法: $0 [-cn] [--registry URL]

安装 Pi extensions:
  ${PLAN_MODE_SOURCE}
  ${SIMPLIFY_SOURCE}
  ${SUBAGENTS_SOURCE}
  ${HASHLINE_SOURCE}
  ${FOOTER_SOURCE}

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

for source in "$PLAN_MODE_SOURCE" "$SIMPLIFY_SOURCE" "$SUBAGENTS_SOURCE" "$HASHLINE_SOURCE" "$FOOTER_SOURCE"; do
    echo "安装 Pi extension: $source"
    pi install "$source"
done

bash "$SCRIPT_DIR/pi/extensions/install-extensions.sh"

echo "Pi extensions 已安装。Pi 中使用 /reload 后生效；也可以重启 pi。"
