#!/bin/bash
# 安装 Oh My Bash 并配置 ~/.bashrc（theme、env.d 加载、PATH）

set -e

ENV_DIR="$HOME/.config/env.d"
GITHUB_PROXY="https://gh-proxy.com/"

usage() {
    cat << EOF
用法: $0

环境变量:
  CN=1     通过国内代理下载 GitHub 文件与克隆仓库
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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

proxy_url() {
    if [[ "${CN:-}" == "1" ]]; then
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

omb_dir="$HOME/.oh-my-bash"
omb_url="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"
omb_repo="https://github.com/ohmybash/oh-my-bash.git"
rcfile="$HOME/.bashrc"
theme="purity"

if [[ -d "$omb_dir" ]]; then
    echo "Oh My Bash 已安装: $omb_dir"
else
    echo "安装 Oh My Bash..."
    REMOTE="$(proxy_url "$omb_repo")" \
        bash -c "$(curl -fsSL "$(proxy_url "$omb_url")")"
fi

mkdir -p "$ENV_DIR"

[[ -f "$rcfile" ]] || touch "$rcfile"
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
