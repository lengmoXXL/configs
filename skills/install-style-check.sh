#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/skill/style-check"
dest_root="${CODEX_HOME:-$HOME/.codex}/skills"
dest="$dest_root/style-check"

if [[ ! -f "$src/SKILL.md" ]]; then
  echo "Missing skill source: $src" >&2
  exit 1
fi

mkdir -p "$dest_root"
rm -rf "$dest"
cp -a "$src" "$dest"

echo "Installed style-check to $dest"
