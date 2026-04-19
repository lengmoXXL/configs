#!/bin/bash
# 创建隔离的 Python 3.11 虚拟环境到 ~/.local/python3.11
# 可重入：已创建时跳过

set -e

INSTALL_DIR="${HOME}/.local/python3.11"
BIN_DIR="${HOME}/.local/bin"
SYSTEM_PYTHON="/usr/bin/python3.11"

# 检查系统 Python 3.11 是否存在
if [[ ! -x "$SYSTEM_PYTHON" ]]; then
    echo "错误: 系统未安装 Python 3.11"
    echo "请先安装: sudo yum install python3.11 python3.11-pip"
    exit 1
fi

# 检查是否已创建虚拟环境
if [[ -x "$INSTALL_DIR/bin/python3" ]]; then
    echo "Python 3.11 虚拟环境已存在: $($INSTALL_DIR/bin/python3 --version)"
    exit 0
fi

echo "创建 Python 3.11 虚拟环境: $INSTALL_DIR"

mkdir -p "$BIN_DIR"

# 创建虚拟环境
"$SYSTEM_PYTHON" -m venv "$INSTALL_DIR" --copies

# 升级 pip
"$INSTALL_DIR/bin/python3" -m pip install --upgrade pip -q

# 预装常用包
echo "安装常用 Python 包..."
"$INSTALL_DIR/bin/pip3" install pypinyin -q

# 创建符号链接到 ~/.local/bin
ln -sf "$INSTALL_DIR/bin/python3" "$BIN_DIR/python3"
ln -sf "$INSTALL_DIR/bin/pip3" "$BIN_DIR/pip3"

# 配置 Python 环境变量
ENV_DIR="$HOME/.config/env.d"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/python.sh" << 'EOF'
# Python 环境配置
export PATH="$HOME/.local/python3.11/bin:$PATH"
EOF

echo ""
echo "Python 3.11 虚拟环境创建完成"
echo "  python: $($INSTALL_DIR/bin/python3 --version)"
echo "  pip: $($INSTALL_DIR/bin/pip3 --version | head -1)"
echo ""
echo "请运行 'source ~/.bashrc' 使环境变量生效"