#!/bin/bash
# 安装固定版本的 Neovim；升级时先用 tools/github-release-latest.sh 查询最新 tag，再改 VERSION
#   macOS: 官方预编译包（无需 cmake/gettext）
#   Linux: 源码编译

set -euo pipefail

INSTALL_DIR="${HOME}/.local"
BIN_DIR="${INSTALL_DIR}/bin"
NVIM_BIN="${BIN_DIR}/nvim"
VERSION="v0.12.5"
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

require_deps() {
    for dep in "$@"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "错误: 缺少依赖 $dep"
            exit 1
        fi
    done
}

TMP_DIR=""
cleanup() {
    if [[ -n "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

# 已安装同版本则直接退出；不同版本询问后覆盖
check_existing_install() {
    [[ -x "$NVIM_BIN" ]] || return 0

    local installed_version
    installed_version="$("$NVIM_BIN" --version | head -1 | awk '{print $2}')"

    if [[ "$installed_version" == "$VERSION" ]]; then
        echo "Neovim ${VERSION} 已安装: $NVIM_BIN"
        exit 0
    fi

    echo "检测到已安装 Neovim: ${installed_version:-unknown}"
    echo "目标版本: ${VERSION}"

    local answer=""
    read -r -p "是否升级到 ${VERSION} 并重新安装? [y/N] " answer || answer=""
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "已取消升级"
        exit 0
    fi
}

# 下载并解压到临时目录，输出解压后的根目录路径
download_release() {
    local url="$1"
    if [[ "$USE_CN" == "true" ]]; then
        url="${GITHUB_RELEASE_PROXY}${url}"
    fi

    TMP_DIR="$(mktemp -d)"
    local tarball="${TMP_DIR}/neovim.tar.gz"

    echo "下载 Neovim ${VERSION}..." >&2
    curl -fL "$url" -o "$tarball"
    tar -xzf "$tarball" -C "$TMP_DIR"

    find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1
}

install_macos() {
    local url="https://github.com/neovim/neovim/releases/download/${VERSION}/nvim-macos-$(uname -m).tar.gz"
    local nvim_root
    nvim_root="$(download_release "$url")"

    if [[ ! -x "$nvim_root/bin/nvim" ]]; then
        echo "错误: 发布包中没有找到 nvim 可执行文件"
        exit 1
    fi

    echo "安装中..."
    mkdir -p "$INSTALL_DIR"
    cp -R "$nvim_root/"* "$INSTALL_DIR/"
}

install_linux() {
    require_deps cmake gettext make nproc

    local url="https://github.com/neovim/neovim/archive/refs/tags/${VERSION}.tar.gz"
    local nvim_root
    nvim_root="$(download_release "$url")"

    if [[ ! -f "$nvim_root/Makefile" ]]; then
        echo "错误: Neovim 源码包中没有找到 Makefile"
        exit 1
    fi

    echo "编译中..."
    make -C "$nvim_root" \
        CMAKE_BUILD_TYPE=Release \
        CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}" \
        -j"$(nproc)"

    echo "安装中..."
    make -C "$nvim_root" install
}

setup_alias() {
    local env_dir="${HOME}/.config/env.d"
    local alias_file="${env_dir}/alias.sh"

    mkdir -p "$env_dir"

    if [[ -f "$alias_file" ]] && grep -q '^alias v=' "$alias_file"; then
        local tmp_alias
        tmp_alias="$(mktemp)"
        sed 's|^alias v=.*|alias v="nvim"|' "$alias_file" > "$tmp_alias"
        mv "$tmp_alias" "$alias_file"
    else
        echo 'alias v="nvim"' >> "$alias_file"
    fi

    echo ""
    echo "已配置 alias v='nvim' 在 $alias_file"
}

require_deps awk curl find head mktemp sed tar
check_existing_install

case "$(uname -s)" in
    Darwin) install_macos ;;
    *) install_linux ;;
esac

echo ""
echo "Neovim ${VERSION} 安装完成"
echo "  binary: $NVIM_BIN"
echo "  clipboard: OSC 52 (终端协议，无需额外工具)"
"$NVIM_BIN" --version | head -1

setup_alias
