#!/bin/bash
# 安装 tldr 命令行帮助工具到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
PYTHON_DIR="${HOME}/.local/python3.11"
UV_BIN="${BIN_DIR}/uv"

mkdir -p "$BIN_DIR"

if command -v tldr &>/dev/null; then
    echo "tldr 已安装: $(command -v tldr)"
    tldr --version
    exit 0
fi

if [[ ! -x "$PYTHON_DIR/bin/python3" ]]; then
    echo "错误: Python 3.11 环境未安装"
    echo "请先运行 install/sys/install-python.sh"
    exit 1
fi

if ! command -v uv &>/dev/null && [[ ! -x "$UV_BIN" ]]; then
    echo "安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if command -v uv &>/dev/null; then
    UV_CMD="$(command -v uv)"
elif [[ -x "$UV_BIN" ]]; then
    UV_CMD="$UV_BIN"
else
    echo "错误: uv 安装后未找到，请确认 $BIN_DIR 在 PATH 中"
    exit 1
fi

echo "安装 tldr 到 Python 3.11 环境..."
"$UV_CMD" pip install --python "$PYTHON_DIR/bin/python3" tldr

if [[ ! -x "$PYTHON_DIR/bin/tldr" ]]; then
    echo "错误: tldr 安装后未找到: $PYTHON_DIR/bin/tldr"
    exit 1
fi

ln -sf "$PYTHON_DIR/bin/tldr" "$BIN_DIR/tldr"

echo ""
echo "tldr 安装完成"
echo "  tldr: $(command -v tldr || echo "$BIN_DIR/tldr")"
"$PYTHON_DIR/bin/tldr" --version
