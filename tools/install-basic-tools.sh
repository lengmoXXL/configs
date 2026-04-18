#!/bin/bash
# 安装基础命令行工具到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
SHARE_DIR="${HOME}/.local/share"
FZF_DIR="${SHARE_DIR}/fzf"
FZF_REPO="https://github.com/junegunn/fzf.git"
RIPGREP_API="https://api.github.com/repos/BurntSushi/ripgrep/releases/latest"
CMAKE_API="https://api.github.com/repos/Kitware/CMake/releases/latest"
CMAKE_DIR="${HOME}/.local/cmake"
ENV_DIR="${HOME}/.config/env.d"

mkdir -p "$BIN_DIR" "$SHARE_DIR"

check_deps() {
    local deps=("curl" "git" "tar" "sed")
    local dep

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "错误: 缺少依赖 $dep"
            exit 1
        fi
    done
}

install_fzf() {
    local fzf_bin
    fzf_bin="$(command -v fzf 2>/dev/null || true)"

    if [[ -z "$fzf_bin" && -x "$BIN_DIR/fzf" ]]; then
        fzf_bin="$BIN_DIR/fzf"
    fi

    if [[ -n "$fzf_bin" ]]; then
        echo "fzf 已安装: $fzf_bin"
        "$fzf_bin" --version
    else
        if [[ -d "$FZF_DIR/.git" ]]; then
            echo "更新 fzf 源码: $FZF_DIR"
            git -C "$FZF_DIR" pull --ff-only
        else
            echo "克隆 fzf 到: $FZF_DIR"
            git clone --depth 1 "$FZF_REPO" "$FZF_DIR"
        fi

        echo "安装 fzf 到: $BIN_DIR"
        "$FZF_DIR/install" --bin
        ln -sf "$FZF_DIR/bin/fzf" "$BIN_DIR/fzf"
    fi

    # 创建 fzf bash 配置
    mkdir -p "$ENV_DIR"
    cat > "${ENV_DIR}/fzf.sh" << 'EOF'
# fzf key bindings
if [[ -f "${HOME}/.local/share/fzf/shell/key-bindings.bash" ]]; then
    source "${HOME}/.local/share/fzf/shell/key-bindings.bash"
fi
EOF
    echo "创建 fzf 配置: ${ENV_DIR}/fzf.sh"
}

install_rg() {
    local version arch target url tmp_dir tarball rg_bin existing_rg

    existing_rg="$(command -v rg 2>/dev/null || true)"
    if [[ -z "$existing_rg" && -x "$BIN_DIR/rg" ]]; then
        existing_rg="$BIN_DIR/rg"
    fi

    if [[ -n "$existing_rg" ]]; then
        echo "rg 已安装: $existing_rg"
        "$existing_rg" --version | head -1
        return
    fi

    version=$(curl -fsSL "$RIPGREP_API" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
    if [[ -z "$version" ]]; then
        echo "错误: 无法获取 ripgrep 最新版本"
        exit 1
    fi

    arch=$(uname -m)
    case "$arch" in
        x86_64) target="x86_64-unknown-linux-musl" ;;
        aarch64 | arm64) target="aarch64-unknown-linux-gnu" ;;
        *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
    esac

    url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-${target}.tar.gz"
    tmp_dir=$(mktemp -d)
    tarball="${tmp_dir}/ripgrep.tar.gz"

    echo "下载 ripgrep ${version}..."
    curl -fL "$url" -o "$tarball"
    tar -xzf "$tarball" -C "$tmp_dir"

    rg_bin=$(find "$tmp_dir" -type f -name rg | head -1)
    if [[ -z "$rg_bin" ]]; then
        echo "错误: ripgrep 压缩包中没有找到 rg"
        rm -rf "$tmp_dir"
        exit 1
    fi

    install -m 755 "$rg_bin" "$BIN_DIR/rg"
    rm -rf "$tmp_dir"

    echo "rg 安装完成: $BIN_DIR/rg"
    "$BIN_DIR/rg" --version | head -1
}

install_cmake() {
    local version arch url tmp_dir tarball existing_cmake

    existing_cmake="$(command -v cmake 2>/dev/null || true)"
    if [[ -z "$existing_cmake" && -x "$BIN_DIR/cmake" ]]; then
        existing_cmake="$BIN_DIR/cmake"
    fi

    if [[ -n "$existing_cmake" ]]; then
        echo "cmake 已安装: $existing_cmake"
        "$existing_cmake" --version | head -1
        return
    fi

    version=$(curl -fsSL "$CMAKE_API" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)
    if [[ -z "$version" ]]; then
        echo "错误: 无法获取 CMake 最新版本"
        exit 1
    fi

    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
    esac

    url="https://github.com/Kitware/CMake/releases/download/v${version}/cmake-${version}-linux-${arch}.tar.gz"
    tmp_dir=$(mktemp -d)
    tarball="${tmp_dir}/cmake.tar.gz"

    echo "下载 CMake ${version}..."
    curl -fL "$url" -o "$tarball"

    rm -rf "$CMAKE_DIR"
    mkdir -p "$CMAKE_DIR"
    tar -xzf "$tarball" -C "$CMAKE_DIR" --strip-components=1
    rm -rf "$tmp_dir"

    ln -sf "$CMAKE_DIR/bin/cmake" "$BIN_DIR/cmake"
    ln -sf "$CMAKE_DIR/bin/ctest" "$BIN_DIR/ctest"
    ln -sf "$CMAKE_DIR/bin/cpack" "$BIN_DIR/cpack"

    echo "cmake 安装完成: $BIN_DIR/cmake"
    "$BIN_DIR/cmake" --version | head -1
}

check_deps
install_fzf
install_rg
install_cmake

echo ""
echo "基础命令行工具安装完成"
echo "确保 $BIN_DIR 在 PATH 中"
