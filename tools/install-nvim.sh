#!/bin/bash

# 从源码编译安装 Neovim v0.11
# https://github.com/neovim/neovim

INSTALL_DIR="${HOME}/.local"
SRC_DIR="${HOME}/.local/src/neovim"
NVIM_REPO="https://github.com/neovim/neovim.git"
VERSION="v0.11.7"

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

# 克隆或更新源码
if [[ -d "$SRC_DIR/.git" ]]; then
    echo "源码目录已存在，更新中..."
    cd "$SRC_DIR"
    git fetch --depth 1 origin tag "$VERSION"
    git checkout "$VERSION"
else
    echo "克隆 Neovim 源码..."
    mkdir -p "$(dirname "$SRC_DIR")"
    git clone --depth 1 --branch "$VERSION" "$NVIM_REPO" "$SRC_DIR"
    cd "$SRC_DIR"
fi

echo "编译中..."
make CMAKE_BUILD_TYPE=Release \
     CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}" \
     -j$(nproc)

echo "安装中..."
make install

echo ""
echo "✓ Neovim ${VERSION} 安装完成"
echo "  binary: $NVIM_BIN"
echo "  source: $SRC_DIR"
$NVIM_BIN --version | head -1
