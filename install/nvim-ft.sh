#!/bin/bash

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PATH="${SCRIPT_DIR}/../tools/nvim_ft.py"
TARGET_PATH="${BIN_DIR}/nvim-ft"

if [[ ! -f "${SOURCE_PATH}" ]]; then
    echo "Error: Source script not found: ${SOURCE_PATH}" >&2
    exit 1
fi

mkdir -p "${BIN_DIR}"
install -m 755 "${SOURCE_PATH}" "${TARGET_PATH}"

echo "Installed nvim-ft to ${TARGET_PATH}"
echo "Run it with: nvim-ft set <file> <filetype>"
echo "Config file: ${XDG_DATA_HOME:-${HOME}/.local/share}/nvim/filetypes.json"
