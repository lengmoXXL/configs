#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/skills/code-style"
dest_root="${AGENTS_HOME:-$HOME/.agents}/skills"
dest="$dest_root/code-style"

if [[ ! -f "$src/SKILL.md" ]]; then
  echo "Missing skill source: $src" >&2
  exit 1
fi

mkdir -p "$dest_root"
rm -rf "$dest"
cp -a "$src" "$dest"

echo "Installed code-style to $dest"

for legacy in style-check doc-style; do
  dir="$dest_root/$legacy"
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
    echo "Removed legacy $legacy from $dir"
  fi
done
