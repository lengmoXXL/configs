#!/bin/bash
# 安装隔离的 Rust 环境到 ~/.local/rust
# 可重入：已安装时跳过

set -e

INSTALL_DIR="${HOME}/.local/rust"
BIN_DIR="${HOME}/.local/bin"

export RUSTUP_HOME="$INSTALL_DIR/rustup"
export CARGO_HOME="$INSTALL_DIR"

# 配置 rustup 阿里云镜像
export RUSTUP_DIST_SERVER="https://mirrors.aliyun.com/rustup"
export RUSTUP_UPDATE_ROOT="https://mirrors.aliyun.com/rustup/rustup"

# 检查是否已安装
if [[ -x "$INSTALL_DIR/bin/cargo" ]]; then
    echo "Rust 已安装: $($INSTALL_DIR/bin/rustc --version)"
    exit 0
fi

echo "安装 Rust 到: $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# 配置 cargo 中科大镜像
cat > "$INSTALL_DIR/config.toml" << 'EOF'
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "https://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --default-toolchain stable

# 创建符号链接到 ~/.local/bin
ln -sf "$INSTALL_DIR/bin/cargo" "$BIN_DIR/cargo"
ln -sf "$INSTALL_DIR/bin/rustc" "$BIN_DIR/rustc"
ln -sf "$INSTALL_DIR/bin/rustup" "$BIN_DIR/rustup"

# 配置 Rust 环境变量
ENV_DIR="$HOME/.config/env.d"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/rust.sh" << 'EOF'
# Rust 环境配置
export RUSTUP_HOME="$HOME/.local/rust/rustup"
export CARGO_HOME="$HOME/.local/rust"
export RUSTUP_DIST_SERVER="https://mirrors.aliyun.com/rustup"
export RUSTUP_UPDATE_ROOT="https://mirrors.aliyun.com/rustup/rustup"
EOF

echo ""
echo "Rust 安装完成"
echo "  rustc: $($INSTALL_DIR/bin/rustc --version)"
echo "  cargo: $($INSTALL_DIR/bin/cargo --version)"
echo ""
echo "请运行 'source ~/.bashrc' 使环境变量生效"