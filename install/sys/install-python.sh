#!/bin/bash
# 使用 uv 创建隔离的 Python 3.11 虚拟环境到 ~/.local/python3.11
# 可重入：已创建时跳过

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/network.sh"
configs_parse_network_args "$@"
set -- "${CONFIGS_ARGS[@]}"

INSTALL_DIR="${HOME}/.local/python3.11"
BIN_DIR="${HOME}/.local/bin"
ENV_DIR="$HOME/.config/env.d"
UV_BIN="${BIN_DIR}/uv"
UV_INSTALL_URL="${UV_INSTALL_URL:-https://astral.sh/uv/install.sh}"

mkdir -p "$BIN_DIR"

if ! command -v uv &>/dev/null && [[ ! -x "$UV_BIN" ]]; then
    echo "安装 uv..."
    curl -LsSf "$UV_INSTALL_URL" | sh
fi

if command -v uv &>/dev/null; then
    UV_CMD="$(command -v uv)"
elif [[ -x "$UV_BIN" ]]; then
    UV_CMD="$UV_BIN"
else
    echo "错误: uv 安装后未找到，请确认 $BIN_DIR 在 PATH 中"
    exit 1
fi

# 检查是否已创建虚拟环境
if [[ -x "$INSTALL_DIR/bin/python3" ]]; then
    echo "Python 3.11 虚拟环境已存在: $($INSTALL_DIR/bin/python3 --version)"
    exit 0
fi

echo "创建 Python 3.11 虚拟环境: $INSTALL_DIR"

"$UV_CMD" python install 3.11
"$UV_CMD" venv --seed --python 3.11 "$INSTALL_DIR"

# 创建符号链接到 ~/.local/bin
ln -sf "$INSTALL_DIR/bin/python3" "$BIN_DIR/python3"
if [[ -x "$INSTALL_DIR/bin/pip3" ]]; then
    ln -sf "$INSTALL_DIR/bin/pip3" "$BIN_DIR/pip3"
elif [[ -x "$INSTALL_DIR/bin/pip" ]]; then
    ln -sf "$INSTALL_DIR/bin/pip" "$BIN_DIR/pip3"
fi

# 配置 Python 环境变量
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/python.sh" << 'EOF'
# Python 环境配置
export PATH="$HOME/.local/python3.11/bin:$PATH"
EOF

echo ""
echo "Python 3.11 虚拟环境创建完成"
echo "  python: $($INSTALL_DIR/bin/python3 --version)"
if [[ -x "$INSTALL_DIR/bin/pip3" ]]; then
    echo "  pip: $($INSTALL_DIR/bin/pip3 --version | head -1)"
elif [[ -x "$INSTALL_DIR/bin/pip" ]]; then
    echo "  pip: $($INSTALL_DIR/bin/pip --version | head -1)"
fi
echo "  uv: $("$UV_CMD" --version)"
echo ""
echo "请运行 'source ~/.bashrc' 使环境变量生效"
