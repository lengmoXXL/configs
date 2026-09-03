#!/bin/bash
# Install or update Kimi Code CLI via the official install script:
#   curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
# The script downloads the latest native binary, verifies its checksum,
# writes ~/.kimi-code/bin to PATH, and migrates any legacy Python `kimi-cli`
# shim on PATH to `kimi-legacy`.
# Set KIMI_VERSION to install a pinned version, KIMI_NO_MODIFY_PATH to skip
# the PATH update (see the header of the official script).

set -euo pipefail

curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash

kimi --version
