#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/skills/code-report"
dest_root="${AGENTS_HOME:-$HOME/.agents}/skills"
dest="$dest_root/code-report"

if [[ ! -f "$src/SKILL.md" ]]; then
  echo "Missing skill source: $src" >&2
  exit 1
fi

mkdir -p "$dest_root"
rm -rf "$dest"
cp -a "$src" "$dest"

echo "Installed code-report to $dest"
