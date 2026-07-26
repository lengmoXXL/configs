#!/bin/bash
# Install or update Pi Agent from npm.
# The installed version is pinned here; use `npm view @earendil-works/pi-coding-agent version` to check updates.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
NPM_PREFIX="${HOME}/.local"
PI_PACKAGE="@earendil-works/pi-coding-agent"
PI_VERSION="0.82.1"
PI_BIN="${BIN_DIR}/pi"
MIN_NODE_VERSION="22.19.0"
USE_CN=false
NPM_REGISTRY=""

usage() {
    cat << EOF
用法: $0 [-cn] [--registry URL]

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

node_ready() {
    command -v node &>/dev/null &&
        command -v npm &>/dev/null &&
        node -e '
            const [major, minor, patch] = process.versions.node.split(".").map(Number);
            process.exit(major > 22 || (major === 22 && (minor > 19 || (minor === 19 && patch >= 0))) ? 0 : 1);
        ' &>/dev/null
}

ensure_node() {
    if node_ready; then
        return
    fi

    echo "Pi Agent 需要 Node.js ${MIN_NODE_VERSION}+ 和 npm"
    echo "尝试通过 install/install-node.sh 安装 Node.js..."
    bash "$SCRIPT_DIR/install-node.sh"
    export PATH="${HOME}/.local/bin:${HOME}/.local/node/bin:${PATH}"

    if ! node_ready; then
        echo "错误: Node.js 或 npm 不满足 Pi Agent 要求"
        echo "当前 node: $(node --version 2>/dev/null || echo missing)"
        echo "当前 npm: $(npm --version 2>/dev/null || echo missing)"
        exit 1
    fi
}

for dep in grep head; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

ensure_node

local_pi=""
if [[ -x "$PI_BIN" ]]; then
    local_pi="$PI_BIN"
else
    local_pi="$(command -v pi 2>/dev/null || true)"
fi

local_version=""
if [[ -n "$local_pi" ]]; then
    local_version=$("$local_pi" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi

if [[ -n "$local_pi" && "$local_version" == "$PI_VERSION" ]]; then
    echo "Pi Agent ${PI_VERSION} 已安装: $local_pi"
    exit 0
fi

if [[ -n "$local_pi" ]]; then
    echo "当前 Pi Agent: ${local_version:-unknown} (${local_pi})"
    echo "目标 Pi Agent: ${PI_VERSION}"
    echo "版本不匹配，将安装目标版本"
else
    echo "Pi Agent 未安装，将安装目标版本 ${PI_VERSION}"
fi

mkdir -p "$BIN_DIR"

npm_args=(
    install -g
    --ignore-scripts
    --min-release-age=0
    --prefix "$NPM_PREFIX"
    --no-fund
    --no-audit
    --loglevel=error
    --progress=false
)

if [[ -n "$NPM_REGISTRY" ]]; then
    npm_args+=(--registry "$NPM_REGISTRY")
fi

npm_args+=("${PI_PACKAGE}@${PI_VERSION}")

echo "安装 Pi Agent ${PI_VERSION}..."
npm "${npm_args[@]}"

echo "Pi Agent 安装完成: $PI_BIN"
"$PI_BIN" --version
echo "提示: 可运行 ./configs/install-pi-extensions.sh 安装 Pi extensions"
