#!/bin/bash
# 安装 Oh My Zsh 并配置 ~/.zshrc（theme、env.d 加载、PATH）

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

# write_managed_block <rcfile> <begin_marker> <end_marker> <block_file>
# 已存在 block 则整体替换，否则追加到文件末尾
write_managed_block() {
    local rcfile="$1"
    local begin_marker="$2"
    local end_marker="$3"
    local block_file="$4"

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

omz_dir="$HOME/.oh-my-zsh"
omz_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
omz_repo="https://github.com/ohmyzsh/ohmyzsh.git"
rcfile="$HOME/.zshrc"
theme="refined"

if [[ -d "$omz_dir" ]]; then
    echo "Oh My Zsh 已安装: $omz_dir"
else
    echo "安装 Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes REMOTE="$(proxy_url "$omz_repo")" \
        sh -c "$(curl -fsSL "$(proxy_url "$omz_url")")"
fi

mkdir -p "$ENV_DIR"

[[ -f "$rcfile" ]] || touch "$rcfile"
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
