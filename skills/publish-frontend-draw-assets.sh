#!/usr/bin/env bash
set -euo pipefail

skills_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_file="${FRONTEND_DRAW_RUNTIME_FILE:-$skills_dir/frontend-draw/assets/frontend-draw.js}"
style_file="${FRONTEND_DRAW_STYLE_FILE:-$skills_dir/frontend-draw/assets/frontend-draw.css}"
bucket="${FRONTEND_DRAW_OSS_BUCKET:-lengmo-asserts}"
object_key="${FRONTEND_DRAW_OSS_KEY:-js/frontend-draw.js}"
style_object_key="${FRONTEND_DRAW_CSS_OSS_KEY:-css/frontend-draw.css}"
cache_control="${FRONTEND_DRAW_CACHE_CONTROL:-public, max-age=300}"
endpoint="${FRONTEND_DRAW_OSS_ENDPOINT:-${OSS_ENDPOINT:-}}"
public_base_url="${FRONTEND_DRAW_PUBLIC_BASE_URL:-https://lengmo-asserts.oss-cn-beijing.aliyuncs.com}"
destination="oss://$bucket/$object_key"
style_destination="oss://$bucket/$style_object_key"

if [[ ! -f "$source_file" ]]; then
  echo "Runtime file not found: $source_file" >&2
  exit 1
fi

if [[ ! -f "$style_file" ]]; then
  echo "Style file not found: $style_file" >&2
  exit 1
fi

runtime_version="$(sed -n 's/^  const version = "\(.*\)";$/\1/p' "$source_file" | head -n 1)"

js_args=(
  cp
  "$source_file"
  "$destination"
  --force
  --content-type "application/javascript; charset=utf-8"
  --cache-control "$cache_control"
)

css_args=(
  cp
  "$style_file"
  "$style_destination"
  --force
  --content-type "text/css; charset=utf-8"
  --cache-control "$cache_control"
)

if [[ -n "$endpoint" ]]; then
  js_args+=(--endpoint "$endpoint")
  css_args+=(--endpoint "$endpoint")
fi

if [[ "${DRY_RUN:-}" == "1" ]]; then
  js_args+=(--dry-run)
  css_args+=(--dry-run)
fi

ossutil "${js_args[@]}"
ossutil "${css_args[@]}"

if [[ "${DRY_RUN:-}" == "1" ]]; then
  echo "Dry run checked $source_file -> $destination"
  echo "Dry run checked $style_file -> $style_destination"
  if [[ -n "$runtime_version" ]]; then
    echo "Style URL: ${public_base_url%/}/$style_object_key?v=$runtime_version"
    echo "Runtime URL: ${public_base_url%/}/$object_key?v=$runtime_version"
  fi
  exit 0
fi

echo "Published $source_file to $destination"
echo "Published $style_file to $style_destination"
if [[ -n "$runtime_version" ]]; then
  echo "Style URL: ${public_base_url%/}/$style_object_key?v=$runtime_version"
  echo "Runtime URL: ${public_base_url%/}/$object_key?v=$runtime_version"
else
  echo "Style URL: ${public_base_url%/}/$style_object_key"
  echo "Runtime URL: ${public_base_url%/}/$object_key"
fi
