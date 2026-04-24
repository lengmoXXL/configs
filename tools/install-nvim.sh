#!/bin/bash

# 从源码编译安装 Neovim v0.12.2
# https://github.com/neovim/neovim
# 可重入：已安装目标版本时跳过，版本不一致时询问是否升级
# 剪贴板使用 OSC 52 终端协议，无需额外安装 xclip

set -e

INSTALL_DIR="${HOME}/.local"
SRC_DIR="${HOME}/.local/src/neovim"
NVIM_REPO="https://github.com/neovim/neovim.git"
VERSION="v0.12.2"

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

# 如果已安装则检查版本
if [[ -x "$NVIM_BIN" ]]; then
    INSTALLED_VERSION="$($NVIM_BIN --version | head -1 | awk '{print $2}')"

    if [[ "$INSTALLED_VERSION" == "$VERSION" ]]; then
        echo "Neovim ${VERSION} 已安装: $NVIM_BIN"
        exit 0
    fi

    echo "检测到已安装 Neovim: ${INSTALLED_VERSION:-unknown}"
    echo "目标版本: ${VERSION}"

    read -r -p "是否升级到 ${VERSION} 并重新安装? [y/N] " ANSWER || ANSWER=""
    if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
        echo "已取消升级"
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
echo "Neovim ${VERSION} 安装完成"
echo "  binary: $NVIM_BIN"
echo "  clipboard: OSC 52 (终端协议，无需额外工具)"
$NVIM_BIN --version | head -1

# 创建或更新 alias 配置
ENV_DIR="${HOME}/.config/env.d"
ALIAS_FILE="${ENV_DIR}/alias.sh"

mkdir -p "$ENV_DIR"

if [[ -f "$ALIAS_FILE" ]]; then
    if grep -q '^alias v=' "$ALIAS_FILE"; then
        sed -i 's|^alias v=.*|alias v="nvim"|' "$ALIAS_FILE"
    else
        echo 'alias v="nvim"' >> "$ALIAS_FILE"
    fi
else
    echo 'alias v="nvim"' > "$ALIAS_FILE"
fi

echo ""
echo "已配置 alias v='nvim' 在 $ALIAS_FILE"
