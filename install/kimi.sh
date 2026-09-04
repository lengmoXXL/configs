#!/bin/bash
# Install or update Kimi Code CLI via the official install script:
#   curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
# The script downloads the latest native binary, verifies its checksum,
# writes ~/.kimi-code/bin to PATH, and migrates any legacy Python `kimi-cli`
# shim on PATH to `kimi-legacy`.
# Set KIMI_VERSION to install a pinned version, KIMI_NO_MODIFY_PATH to skip
# the PATH update (see the header of the official script).

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools" && pwd)/common.sh"

if [[ "${UPDATE:-}" == "1" ]] && ! command -v kimi &>/dev/null; then
    echo "未安装，跳过: kimi"
    exit 0
fi

if [[ "${UPDATE:-}" == "1" ]]; then
    confirm_update "kimi 到最新版" || exit 0
fi

curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash

kimi --version
