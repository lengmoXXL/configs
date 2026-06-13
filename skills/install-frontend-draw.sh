#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/skills/frontend-draw/skill"
dest_root="${CODEX_HOME:-$HOME/.codex}/skills"
dest="$dest_root/frontend-draw"

if [[ ! -f "$src/SKILL.md" ]]; then
  echo "Missing skill source: $src" >&2
  exit 1
fi

mkdir -p "$dest_root"
rm -rf "$dest"
cp -a "$src" "$dest"

echo "Installed frontend-draw to $dest"
echo "Restart Codex to pick up new skills."
