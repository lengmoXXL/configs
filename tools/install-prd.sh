#!/bin/bash

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/prd"
SOURCE_PATH="${PROJECT_DIR}/dist/prd.cjs"
TARGET_PATH="${BIN_DIR}/prd"

if [[ ! -f "${PROJECT_DIR}/package.json" ]]; then
    echo "Error: prd package not found: ${PROJECT_DIR}" >&2
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    echo "Error: node is required to install prd" >&2
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "Error: npm is required to install prd" >&2
    exit 1
fi

echo "Updating prd dependencies..."
npm --prefix "${PROJECT_DIR}" install

echo "Building prd bundle..."
npm --prefix "${PROJECT_DIR}" run build

if [[ ! -f "${SOURCE_PATH}" ]]; then
    echo "Error: Build output not found: ${SOURCE_PATH}" >&2
    exit 1
fi

mkdir -p "${BIN_DIR}"
install -m 755 "${SOURCE_PATH}" "${TARGET_PATH}"

echo "Installed prd to ${TARGET_PATH}"
echo "Run it with: prd <file>"
echo "Default server: http://127.0.0.1:7000/"
