#!/usr/bin/env bash
set -eu

bin_dir="${HOME}/.local/bin"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_path="${script_dir}/../tools/style-check.sh"
target_path="${bin_dir}/style-check"

mkdir -p "${bin_dir}"
install -m 755 "${source_path}" "${target_path}"

echo "Installed style-check to ${target_path}"
echo "Run it with: style-check [prompt]"
