#!/usr/bin/env bash

_PJ_DIR="${_PJ_DIR:-${HOME}/.pjs}"

pj() {
    local action="${1:-}"

    if [[ "$action" == "-h" || "$action" == "--help" ]]; then
        cat << 'EOF'
pj - 当前 Git 仓库的常用命令

用法:
    pj -s [-l <label>]  从 history 选择命令并保存
    pj -c [label]       执行命令；不指定标签时用 fzf 选择
    pj -h               显示帮助

命令文件: ~/.pjs/<repo>.pjcmds
旧版命令文件会在当前仓库首次运行 pj 时自动迁移。
EOF
        return
    fi

    if [[ "$action" != "-s" && "$action" != "-c" ]]; then
        [[ -n "$action" ]] && echo "错误: 未知选项: $action" || echo "错误: 请指定 -s 或 -c"
        echo "使用 'pj -h' 查看帮助"
        return 1
    fi

    local git_root remote repo cmds_file
    git_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "错误: 当前目录不在 Git 仓库中"
        return 1
    }

    remote=$(git -C "$git_root" config --get remote.origin.url 2>/dev/null || true)
    if [[ -n "$remote" ]]; then
        remote="${remote%/}"
        if [[ "$remote" == */* ]]; then
            repo="${remote##*/}"
        else
            repo="${remote##*:}"
        fi
        repo="${repo%.git}"
    else
        repo="${git_root##*/}"
    fi

    if [[ -z "$repo" || "$repo" == "." || "$repo" == ".." ]]; then
        echo "错误: 无法识别当前 Git 仓库名"
        return 1
    fi

    mkdir -p "$_PJ_DIR" || return
    cmds_file="$_PJ_DIR/$repo.pjcmds"

    # Migrate command files from both legacy layouts on first use in a repo:
    # <repo-root>/.pjcmds and ~/.pjs/<old-project-name>.pjcmds.
    local old_file env_file old_path old_root old_name line
    local -a old_files=("$git_root/.pjcmds")
    if [[ -n "${PJ_CMDS:-}" && -n "${PJ_ROOT:-}" ]]; then
        old_root=$(git -C "$PJ_ROOT" rev-parse --show-toplevel 2>/dev/null || true)
        [[ "$old_root" == "$git_root" ]] && old_files+=("$PJ_CMDS")
    fi
    for env_file in "$_PJ_DIR"/*.env.sh; do
        [[ -f "$env_file" ]] || continue
        old_path=$(sed -n 's/^# Path: *//p' "$env_file" 2>/dev/null)
        [[ -n "$old_path" ]] || continue
        old_root=$(git -C "$old_path" rev-parse --show-toplevel 2>/dev/null || true)
        [[ "$old_root" == "$git_root" ]] || continue
        old_name=$(basename "$env_file" .env.sh)
        old_files+=("$_PJ_DIR/$old_name.pjcmds")
    done
    unset PJ_CMDS PJ_ROOT PJ_NAME

    for old_file in "${old_files[@]}"; do
        [[ -f "$old_file" && "$old_file" != "$cmds_file" ]] || continue
        if [[ ! -e "$cmds_file" ]]; then
            if mv -- "$old_file" "$cmds_file"; then
                echo "已迁移命令: $old_file -> $cmds_file"
            fi
            continue
        fi

        local merge_failed=""
        while IFS= read -r line || [[ -n "$line" ]]; do
            if ! grep -Fqx -- "$line" "$cmds_file" 2>/dev/null; then
                printf '%s\n' "$line" >> "$cmds_file" || {
                    merge_failed=1
                    break
                }
            fi
        done < "$old_file"
        if [[ -z "$merge_failed" ]] && rm -- "$old_file"; then
            echo "已合并命令: $old_file -> $cmds_file"
        fi
    done

    if [[ "$action" == "-s" ]]; then
        local label=""
        shift
        if [[ "${1:-}" == "-l" ]]; then
            label="${2:-}"
            if [[ -z "$label" ]]; then
                echo "错误: -l 需要指定标签"
                return 1
            fi
            shift 2
        fi
        if [[ $# -ne 0 ]]; then
            echo "错误: pj -s 仅支持可选参数 -l <label>"
            return 1
        fi
        if [[ "$label" == *:* || "$label" == *$'\n'* ]]; then
            echo "错误: 标签不能包含冒号或换行"
            return 1
        fi

        local cmd stored_cmd stored_label tmp found=""
        if ! cmd=$(fc -ln 1 | sed 's/^[[:space:]]*//' | fzf --height=40% --layout=reverse --header="Select Command from History"); then
            return
        fi
        [[ -n "$cmd" ]] || return
        touch "$cmds_file" || return

        if [[ -n "$label" ]]; then
            tmp=$(mktemp "$_PJ_DIR/.pjcmds.XXXXXX") || return
            while IFS= read -r line || [[ -n "$line" ]]; do
                if [[ "$line" == *:* ]]; then
                    stored_label="${line%%:*}"
                    stored_cmd="${line#*:}"
                else
                    stored_label=""
                    stored_cmd="$line"
                fi
                [[ "$stored_label" == "$label" || "$stored_cmd" == "$cmd" ]] && continue
                printf '%s\n' "$line" >> "$tmp"
            done < "$cmds_file"
            printf '%s:%s\n' "$label" "$cmd" >> "$tmp"
            mv -- "$tmp" "$cmds_file"
            echo "已保存命令: [$label] $cmd"
            return
        fi

        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" == *:* ]] && stored_cmd="${line#*:}" || stored_cmd="$line"
            if [[ "$stored_cmd" == "$cmd" ]]; then
                found=1
                break
            fi
        done < "$cmds_file"
        if [[ -n "$found" ]]; then
            echo "命令已存在: $cmd"
        else
            printf ':%s\n' "$cmd" >> "$cmds_file"
            echo "已保存命令: $cmd"
        fi
        return
    fi

    if [[ $# -gt 2 ]]; then
        echo "错误: pj -c 仅支持一个可选标签"
        return 1
    fi
    [[ -s "$cmds_file" ]] || {
        echo "错误: 当前仓库还没有保存命令"
        return 1
    }

    local label="${2:-}" selection cmd tmp
    if [[ -n "$label" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *:* && "${line%%:*}" == "$label" ]]; then
                selection="$line"
                break
            fi
        done < "$cmds_file"
        if [[ -z "${selection:-}" ]]; then
            echo "错误: 未找到标签 '$label'"
            return 1
        fi
    else
        if ! selection=$(fzf --height=40% --layout=reverse --header="Select Command" < "$cmds_file"); then
            return
        fi
        [[ -n "$selection" ]] || return
    fi

    [[ "$selection" == *:* ]] && cmd="${selection#*:}" || cmd="$selection"
    tmp=$(mktemp "$_PJ_DIR/.pjcmds.XXXXXX") || return
    {
        printf '%s\n' "$selection"
        grep -Fvx -- "$selection" "$cmds_file" || true
    } > "$tmp"
    mv -- "$tmp" "$cmds_file"

    echo "执行: $cmd"
    eval "$cmd"
}
