#!/bin/bash
# Build Neovim from a fixed GitHub Release source archive.
# The installed version is pinned here; use tools/github-release-latest.sh to check updates.

set -euo pipefail

INSTALL_DIR="${HOME}/.local"
BIN_DIR="${INSTALL_DIR}/bin"
NVIM_BIN="${BIN_DIR}/nvim"
VERSION="v0.12.3"
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

for dep in awk cmake curl find gettext head make mktemp nproc sed tar; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

if [[ -x "$NVIM_BIN" ]]; then
    installed_version="$("$NVIM_BIN" --version | head -1 | awk '{print $2}')"

    if [[ "$installed_version" == "$VERSION" ]]; then
        echo "Neovim ${VERSION} 已安装: $NVIM_BIN"
        exit 0
    fi

    echo "检测到已安装 Neovim: ${installed_version:-unknown}"
    echo "目标版本: ${VERSION}"

    read -r -p "是否升级到 ${VERSION} 并重新安装? [y/N] " answer || answer=""
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "已取消升级"
        exit 0
    fi
fi

tmp_dir=$(mktemp -d)
tarball="${tmp_dir}/neovim-source.tar.gz"
url="https://github.com/neovim/neovim/archive/refs/tags/${VERSION}.tar.gz"
if [[ "$USE_CN" == "true" ]]; then
    url="${GITHUB_RELEASE_PROXY}${url}"
fi

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "下载 Neovim ${VERSION} 源码..."
curl -fL "$url" -o "$tarball"
tar -xzf "$tarball" -C "$tmp_dir"

nvim_root=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
if [[ -z "$nvim_root" || ! -f "$nvim_root/Makefile" ]]; then
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

echo ""
echo "Neovim ${VERSION} 安装完成"
echo "  binary: $NVIM_BIN"
echo "  clipboard: OSC 52 (终端协议，无需额外工具)"
"$NVIM_BIN" --version | head -1

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
