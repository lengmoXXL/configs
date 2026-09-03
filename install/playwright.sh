#!/usr/bin/env bash
# 安装 Playwright CLI、Chromium 系统依赖与 Chromium 浏览器，用于浏览器自动化与截图
# 可重入：重复执行会更新 Playwright，并复用已安装依赖和已下载的浏览器缓存

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"

export PATH="$LOCAL_BIN:$PATH"

run_with_sudo() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo &>/dev/null; then
        sudo "$@"
    else
        echo "Missing dependency: sudo is required to install system packages" >&2
        exit 1
    fi
}

install_chromium_system_deps() {
    echo "Installing Playwright Chromium system dependencies..."

    if command -v apt-get &>/dev/null; then
        "${PLAYWRIGHT_CMD[@]}" install-deps chromium
        return
    fi

    local packages=(
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups-libs
        dbus-libs
        glib2
        gtk3
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libxcb
        libxkbcommon
        mesa-libgbm
        nss
        pango
    )

    if command -v dnf &>/dev/null; then
        run_with_sudo dnf install -y "${packages[@]}"
    elif command -v yum &>/dev/null; then
        run_with_sudo yum install -y "${packages[@]}"
    else
        echo "Unsupported package manager: install Chromium system dependencies manually." >&2
        echo "Required libraries include libatk-bridge-2.0.so.0, GTK3, NSS, Pango, GBM, and X11 libs." >&2
        exit 1
    fi
}

if ! command -v npm &>/dev/null; then
    if [[ -x "$SCRIPT_DIR/compiler/node.sh" ]]; then
        "$SCRIPT_DIR/compiler/node.sh"
        export PATH="$LOCAL_BIN:$PATH"
    else
        echo "Missing dependency: npm" >&2
        exit 1
    fi
fi

mkdir -p "$LOCAL_BIN"
npm config set prefix "$HOME/.local"

echo "Installing Playwright npm package..."
npm install -g playwright

if command -v playwright &>/dev/null; then
    PLAYWRIGHT_CMD=(playwright)
else
    PLAYWRIGHT_CMD=(npx playwright)
fi

install_chromium_system_deps

echo "Installing Playwright Chromium browser..."
"${PLAYWRIGHT_CMD[@]}" install chromium

echo ""
echo "Playwright installed:"
"${PLAYWRIGHT_CMD[@]}" --version
echo "Chromium is ready for Playwright automation."
