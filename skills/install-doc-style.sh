#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/skills/doc-style"
dest_root="${AGENTS_HOME:-$HOME/.agents}/skills"
dest="$dest_root/doc-style"

if [[ ! -f "$src/SKILL.md" ]]; then
  echo "Missing skill source: $src" >&2
  exit 1
fi

mkdir -p "$dest_root"
rm -rf "$dest"
cp -a "$src" "$dest"

echo "Installed doc-style to $dest"
