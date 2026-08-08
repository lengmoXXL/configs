#!/bin/bash
# 安装 shell 框架，并确保 rc 文件加载 ~/.config/env.d/*.sh
#   macOS: Oh My Zsh + ~/.zshrc
#   Linux: Oh My Bash + ~/.bashrc

set -e

ENV_DIR="$HOME/.config/env.d"
USE_CN=false
GITHUB_PROXY="https://gh-proxy.com/"

usage() {
    cat << EOF
用法: $0 [-cn]

选项:
  -cn      通过国内代理下载 GitHub 文件与克隆仓库
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

# proxy_url <url>: -cn 模式下加代理前缀
proxy_url() {
    if [[ "$USE_CN" == "true" ]]; then
        echo "${GITHUB_PROXY}$1"
    else
        echo "$1"
    fi
}

# write_managed_block <rcfile> <begin_marker> <end_marker> <block_file> [insert_before_pattern]
# 已存在 block 则整体替换；否则可选地插到匹配行之前，或追加到文件末尾
write_managed_block() {
    local rcfile="$1"
    local begin_marker="$2"
    local end_marker="$3"
    local block_file="$4"
    local insert_pattern="${5:-}"

    local tmp_rcfile
    tmp_rcfile="$(mktemp)"

    local has_begin=0 has_end=0
    grep -qF "$begin_marker" "$rcfile" && has_begin=1
    grep -qF "$end_marker" "$rcfile" && has_end=1

    if [[ "$has_begin" -ne "$has_end" ]]; then
        echo "错误: $rcfile 中存在不完整的 configs managed block"
        exit 1
    elif [[ "$has_begin" -eq 1 ]]; then
        awk -v begin="$begin_marker" -v end="$end_marker" -v block="$block_file" '
            BEGIN {
                while ((getline line < block) > 0) {
                    replacement = replacement line ORS
                }
            }
            $0 == begin {
                printf "%s", replacement
                in_block = 1
                next
            }
            $0 == end {
                in_block = 0
                next
            }
            !in_block {
                print
            }
        ' "$rcfile" > "$tmp_rcfile"
    elif [[ -n "$insert_pattern" ]] && grep -q "$insert_pattern" "$rcfile"; then
        awk -v block="$block_file" -v pattern="$insert_pattern" '
            BEGIN {
                while ((getline line < block) > 0) {
                    replacement = replacement line ORS
                }
            }
            !inserted && $0 ~ pattern {
                printf "%s", replacement
                inserted = 1
            }
            { print }
        ' "$rcfile" > "$tmp_rcfile"
    elif [[ -s "$rcfile" ]]; then
        cp "$rcfile" "$tmp_rcfile"
        echo "" >> "$tmp_rcfile"
        cat "$block_file" >> "$tmp_rcfile"
    else
        cp "$block_file" "$tmp_rcfile"
    fi

    mv "$tmp_rcfile" "$rcfile"
    echo "$rcfile managed block 已更新"
}

install_macos() {
    local omz_dir="$HOME/.oh-my-zsh"
    local omz_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    local omz_repo="https://github.com/ohmyzsh/ohmyzsh.git"
    local rcfile="$HOME/.zshrc"
    local theme="robbyrussell"

    if [[ -d "$omz_dir" ]]; then
        echo "Oh My Zsh 已安装: $omz_dir"
    else
        echo "安装 Oh My Zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes REMOTE="$(proxy_url "$omz_repo")" \
            sh -c "$(curl -fsSL "$(proxy_url "$omz_url")")"
    fi

    [[ -f "$rcfile" ]] || touch "$rcfile"
    local block
    block="$(mktemp)"
    {
        echo "# BEGIN configs zshrc"
        echo "export ZSH=\"$omz_dir\""
        echo "ZSH_THEME=\"$theme\""
        echo "plugins=(git)"
        echo 'source "$ZSH/oh-my-zsh.sh"'
        echo ""
        echo "# 加载环境变量配置"
        echo 'for env_file in "$HOME/.config/env.d"/*.sh(N); do'
        echo '    source "$env_file"'
        echo 'done'
        echo ""
        echo "# 配置 PATH"
        echo 'case ":$PATH:" in'
        echo '    *":$HOME/.local/bin:"*) ;;'
        echo '    *) export PATH="$HOME/.local/bin:$PATH" ;;'
        echo 'esac'
        echo "# END configs zshrc"
    } > "$block"

    write_managed_block "$rcfile" "# BEGIN configs zshrc" "# END configs zshrc" "$block"
    rm -f "$block"

    echo "Oh My Zsh 配置完成"
    echo "  theme: $theme"
}

install_linux() {
    local omb_dir="$HOME/.oh-my-bash"
    local omb_url="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"
    local omb_repo="https://github.com/ohmybash/oh-my-bash.git"
    local rcfile="$HOME/.bashrc"
    local theme="purity"

    if [[ -d "$omb_dir" ]]; then
        echo "Oh My Bash 已安装: $omb_dir"
    else
        echo "安装 Oh My Bash..."
        REMOTE="$(proxy_url "$omb_repo")" \
            bash -c "$(curl -fsSL "$(proxy_url "$omb_url")")"
    fi

    [[ -f "$rcfile" ]] || touch "$rcfile"
    local block
    block="$(mktemp)"
    {
        echo "# BEGIN configs bashrc"
        echo "OSH_THEME=\"$theme\""
        echo ""
        echo "# 加载环境变量配置"
        echo 'for env_file in "$HOME/.config/env.d"/*.sh; do'
        echo '    [ -f "$env_file" ] || continue'
        echo '    source "$env_file"'
        echo 'done'
        echo ""
        echo "# 配置 PATH"
        echo 'case ":$PATH:" in'
        echo '    *":$HOME/.local/bin:"*) ;;'
        echo '    *) export PATH="$HOME/.local/bin:$PATH" ;;'
        echo 'esac'
        echo "# END configs bashrc"
    } > "$block"

    # Oh My Bash 安装器生成的 bashrc 会 source oh-my-bash.sh，block 需插到它之前让 OSH_THEME 先生效
    write_managed_block "$rcfile" "# BEGIN configs bashrc" "# END configs bashrc" "$block" 'oh-my-bash\.sh'
    rm -f "$block"

    echo "Oh My Bash 配置完成"
    echo "  theme: $theme"
}

mkdir -p "$ENV_DIR"

case "$(uname -s)" in
    Darwin) install_macos ;;
    *) install_linux ;;
esac
