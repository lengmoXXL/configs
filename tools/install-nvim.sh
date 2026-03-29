#!/bin/bash

# 从源码编译安装 Neovim v0.11
# https://github.com/neovim/neovim

set -e

INSTALL_DIR="${HOME}/.local"
NVIM_REPO="https://github.com/neovim/neovim.git"
VERSION="v0.11.7"
PROXY="${GITHUB_PROXY:-https://gh-proxy.com/}"

NVIM_BIN="${INSTALL_DIR}/bin/nvim"

echo "安装 Neovim ${VERSION} 从源码编译"

# 检查依赖
check_deps() {
    local deps=("cmake" "gettext" "unzip" "curl" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "错误: 缺少依赖 $dep"
            exit 1
        fi
    done
}

check_deps

# 如果已安装则跳过
if [[ -x "$NVIM_BIN" ]]; then
    echo "Neovim 已安装: $NVIM_BIN"
    $NVIM_BIN --version | head -1
    read -p "是否重新安装? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        exit 0
    fi
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "克隆 Neovim 源码..."
git clone --depth 1 --branch "$VERSION" "$NVIM_REPO" "$TMPDIR/neovim"

cd "$TMPDIR/neovim"

echo "编译中..."
make CMAKE_BUILD_TYPE=Release \
     CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}" \
     -j$(nproc)

echo "安装中..."
make install

echo ""
echo "✓ Neovim ${VERSION} 安装完成"
echo "  binary: $NVIM_BIN"
$NVIM_BIN --version | head -1
