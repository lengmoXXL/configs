#!/bin/bash
# 安装基础命令行工具到 ~/.local/bin

set -e

BIN_DIR="${HOME}/.local/bin"
SHARE_DIR="${HOME}/.local/share"
FZF_VERSION="0.74.3"
RIPGREP_VERSION="15.2.0"
FD_VERSION="v10.4.2"
CMAKE_VERSION="4.4.2"
CMAKE_DIR="${HOME}/.local/cmake"
ENV_DIR="${HOME}/.config/env.d"
USE_CN=false
GITHUB_RELEASE_PROXY="https://gh-proxy.com/"

usage() {
    cat << EOF
用法: $0 [-cn]

选项:
  -cn      通过国内代理下载 GitHub Release 文件
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
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

mkdir -p "$BIN_DIR" "$SHARE_DIR"

check_deps() {
    local deps=("curl" "tar")
    local dep

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "错误: 缺少依赖 $dep"
            exit 1
        fi
    done
}

install_fzf() {
    local fzf_bin arch target url tmp_dir tarball
    fzf_bin="$(command -v fzf 2>/dev/null || true)"

    if [[ -z "$fzf_bin" && -x "$BIN_DIR/fzf" ]]; then
        fzf_bin="$BIN_DIR/fzf"
    fi

    if [[ -n "$fzf_bin" ]]; then
        echo "fzf 已安装: $fzf_bin"
        "$fzf_bin" --version
    else
        os=$(uname -s)
        arch=$(uname -m)
        case "${os}-${arch}" in
            Darwin-x86_64) target="darwin_amd64" ;;
            Darwin-arm64 | Darwin-aarch64) target="darwin_arm64" ;;
            Linux-x86_64) target="linux_amd64" ;;
            Linux-aarch64 | Linux-arm64) target="linux_arm64" ;;
            *) echo "错误: 不支持的平台 ${os}-${arch}"; exit 1 ;;
        esac

        url="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-${target}.tar.gz"
        if [[ "$USE_CN" == "true" ]]; then
            url="${GITHUB_RELEASE_PROXY}${url}"
        fi
        tmp_dir=$(mktemp -d)
        tarball="${tmp_dir}/fzf.tar.gz"

        echo "下载 fzf ${FZF_VERSION}..."
        curl -fL "$url" -o "$tarball"
        tar -xzf "$tarball" -C "$tmp_dir"
        install -m 755 "$tmp_dir/fzf" "$BIN_DIR/fzf"
        rm -rf "$tmp_dir"

        echo "fzf 安装完成: $BIN_DIR/fzf"
        "$BIN_DIR/fzf" --version
    fi

    # 创建 fzf bash 配置
    mkdir -p "$ENV_DIR"
    cat > "${ENV_DIR}/fzf.sh" << 'EOF'
# fzf key bindings
if command -v fzf &>/dev/null; then
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(fzf --zsh)"
    else
        eval "$(fzf --bash)"
    fi
fi
EOF
    echo "创建 fzf 配置: ${ENV_DIR}/fzf.sh"
}

install_rg() {
    local version os arch target url tmp_dir tarball rg_bin existing_rg

    existing_rg="$(command -v rg 2>/dev/null || true)"
    if [[ -z "$existing_rg" && -x "$BIN_DIR/rg" ]]; then
        existing_rg="$BIN_DIR/rg"
    fi

    if [[ -n "$existing_rg" ]]; then
        echo "rg 已安装: $existing_rg"
        "$existing_rg" --version | head -1
        return
    fi

    version="$RIPGREP_VERSION"

    os=$(uname -s)
    arch=$(uname -m)
    case "${os}-${arch}" in
        Darwin-x86_64) target="x86_64-apple-darwin" ;;
        Darwin-arm64) target="aarch64-apple-darwin" ;;
        Linux-x86_64) target="x86_64-unknown-linux-musl" ;;
        Linux-aarch64 | Linux-arm64) target="aarch64-unknown-linux-gnu" ;;
        *) echo "错误: 不支持的平台 ${os}-${arch}"; exit 1 ;;
    esac

    url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-${target}.tar.gz"
    if [[ "$USE_CN" == "true" ]]; then
        url="${GITHUB_RELEASE_PROXY}${url}"
    fi
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

    version="$CMAKE_VERSION"

    os=$(uname -s)
    arch=$(uname -m)
    case "$os" in
        Darwin)
            # macOS 官方只发布 universal 包
            target="macos-universal"
            ;;
        Linux)
            case "$arch" in
                x86_64) target="linux-x86_64" ;;
                aarch64 | arm64) target="linux-aarch64" ;;
                *) echo "错误: 不支持的架构 $arch"; exit 1 ;;
            esac
            ;;
        *)
            echo "错误: 不支持的系统 $os"
            exit 1
            ;;
    esac

    url="https://github.com/Kitware/CMake/releases/download/v${version}/cmake-${version}-${target}.tar.gz"
    if [[ "$USE_CN" == "true" ]]; then
        url="${GITHUB_RELEASE_PROXY}${url}"
    fi
    tmp_dir=$(mktemp -d)
    tarball="${tmp_dir}/cmake.tar.gz"

    echo "下载 CMake ${version}..."
    curl -fL "$url" -o "$tarball"

    rm -rf "$CMAKE_DIR"
    mkdir -p "$CMAKE_DIR"
    tar -xzf "$tarball" -C "$CMAKE_DIR" --strip-components=1
    rm -rf "$tmp_dir"

    # macOS 包是 CMake.app 结构，Linux 包是平铺 bin/
    if [[ "$os" == "Darwin" ]]; then
        cmake_bin_dir="$CMAKE_DIR/CMake.app/Contents/bin"
    else
        cmake_bin_dir="$CMAKE_DIR/bin"
    fi
    ln -sf "$cmake_bin_dir/cmake" "$BIN_DIR/cmake"
    ln -sf "$cmake_bin_dir/ctest" "$BIN_DIR/ctest"
    ln -sf "$cmake_bin_dir/cpack" "$BIN_DIR/cpack"

    echo "cmake 安装完成: $BIN_DIR/cmake"
    "$BIN_DIR/cmake" --version | head -1
}

install_fd() {
    local version arch target url tmp_dir tarball fd_bin existing_fd

    existing_fd="$(command -v fd 2>/dev/null || true)"
    if [[ -z "$existing_fd" && -x "$BIN_DIR/fd" ]]; then
        existing_fd="$BIN_DIR/fd"
    fi

    if [[ -n "$existing_fd" ]]; then
        echo "fd 已安装: $existing_fd"
        "$existing_fd" --version | head -1
        return
    fi

    version="$FD_VERSION"

    os=$(uname -s)
    arch=$(uname -m)
    case "${os}-${arch}" in
        Darwin-x86_64)
            target="x86_64-apple-darwin"
            version="v10.3.0" # v10.4.0 起不再发布 Intel mac 包
            ;;
        Darwin-arm64 | Darwin-aarch64) target="aarch64-apple-darwin" ;;
        Linux-x86_64) target="x86_64-unknown-linux-musl" ;;
        Linux-aarch64 | Linux-arm64) target="aarch64-unknown-linux-gnu" ;;
        *) echo "错误: 不支持的平台 ${os}-${arch}"; exit 1 ;;
    esac

    url="https://github.com/sharkdp/fd/releases/download/${version}/fd-${version}-${target}.tar.gz"
    if [[ "$USE_CN" == "true" ]]; then
        url="${GITHUB_RELEASE_PROXY}${url}"
    fi
    tmp_dir=$(mktemp -d)
    tarball="${tmp_dir}/fd.tar.gz"

    echo "下载 fd ${version}..."
    curl -fL "$url" -o "$tarball"
    tar -xzf "$tarball" -C "$tmp_dir"

    fd_bin=$(find "$tmp_dir" -type f -name fd | head -1)
    if [[ -z "$fd_bin" ]]; then
        echo "错误: fd 压缩包中没有找到 fd"
        rm -rf "$tmp_dir"
        exit 1
    fi

    install -m 755 "$fd_bin" "$BIN_DIR/fd"
    rm -rf "$tmp_dir"

    echo "fd 安装完成: $BIN_DIR/fd"
    "$BIN_DIR/fd" --version | head -1
}

check_deps
install_fzf
install_rg
install_fd
install_cmake

echo ""
echo "基础命令行工具安装完成"
echo "确保 $BIN_DIR 在 PATH 中"
