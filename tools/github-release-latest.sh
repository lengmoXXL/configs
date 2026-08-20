#!/bin/bash
# Query the latest GitHub Release tag for packages pinned in install scripts.

set -euo pipefail

usage() {
    cat << EOF
Usage: $0 <package|owner/repo>
       $0 --list

Packages:
  ripgrep, rg
  fzf
  fd
  cmake
  tmux
  lua-lsp, lua-language-server
  starpls
  typos-lsp, typos
  codex
  opencode
  herdr
  hermes-agent
  sarasa
  aurulent
  droid, droidsansmono
EOF
}

repo_for_package() {
    case "$1" in
        ripgrep | rg) echo "BurntSushi/ripgrep" ;;
        fzf) echo "junegunn/fzf" ;;
        fd) echo "sharkdp/fd" ;;
        cmake) echo "Kitware/CMake" ;;
        tmux) echo "tmux/tmux" ;;
        lua-lsp | lua-language-server) echo "LuaLS/lua-language-server" ;;
        starpls) echo "withered-magic/starpls" ;;
        typos-lsp | typos) echo "tekumara/typos-lsp" ;;
        codex) echo "openai/codex" ;;
        opencode) echo "anomalyco/opencode" ;;
        herdr) echo "herdrdev/herdr" ;;
        hermes-agent) echo "NousResearch/hermes-agent" ;;
        sarasa) echo "laishulu/Sarasa-Term-SC-Nerd" ;;
        aurulent | droid | droidsansmono) echo "ryanoasis/nerd-fonts" ;;
        */*) echo "$1" ;;
        *) return 1 ;;
    esac
}

script_version_for_package() {
    local package="$1"
    local tag="$2"

    case "$package" in
        cmake) echo "${tag#v}" ;;
        codex) echo "${tag#rust-v}" ;;
        opencode) echo "${tag#v}" ;;
        typos-lsp | typos) echo "${tag#v}" ;;
        *) echo "$tag" ;;
    esac
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "${1:-}" == "--list" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "错误: 缺少依赖 curl"
    exit 1
fi

package="$1"
repo="$(repo_for_package "$package")" || {
    echo "错误: 未知 package: $package"
    usage
    exit 1
}

tag="$(
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" |
        sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' |
        head -1
)"

if [[ -z "$tag" ]]; then
    echo "错误: 无法获取 latest release: $repo"
    exit 1
fi

script_version="$(script_version_for_package "$package" "$tag")"

echo "package: $package"
echo "repo: $repo"
echo "latest tag: $tag"
echo "script version: $script_version"
echo "release: https://github.com/${repo}/releases/tag/${tag}"
