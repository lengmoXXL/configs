#!/bin/bash

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PATH="${SCRIPT_DIR}/../tools/codex_batch.py"
TARGET_PATH="${BIN_DIR}/codex-batch"

if [[ ! -f "${SOURCE_PATH}" ]]; then
    echo "Error: Source script not found: ${SOURCE_PATH}" >&2
    exit 1
fi

mkdir -p "${BIN_DIR}"
install -m 755 "${SOURCE_PATH}" "${TARGET_PATH}"

echo "Installed codex-batch to ${TARGET_PATH}"
echo "Run it with: codex-batch <input.json> <task.md>"
