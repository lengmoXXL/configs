#!/usr/bin/env bash

_PJ_DIR="${HOME}/.pjs"
_PJ_LIB="${HOME}"

_pj_ensure_dirs() {
    mkdir -p "$_PJ_DIR"
}

_pj_list_envs() {
    local env_file
    for env_file in "$_PJ_DIR"/*.env.sh; do
        [[ -f "$env_file" ]] || continue
        basename "$env_file" .env.sh
    done
}

_pj_get_description() {
    local name="$1"
    local env_file="$_PJ_DIR/${name}.env.sh"
    [[ -f "$env_file" ]] || return
    sed -n 's/^# Description: *//p' "$env_file" 2>/dev/null | head -1
}

_pj_get_path() {
    local name="$1"
    local env_file="$_PJ_DIR/${name}.env.sh"
    [[ -f "$env_file" ]] || return
    sed -n 's/^# Path: *//p' "$env_file" 2>/dev/null | head -1
}

_pj_truncate_path() {
    local path="$1"
    local max_len="${2:-80}"
    if [[ ${#path} -gt $max_len ]]; then
        echo "${path: -$max_len}"
    else
        echo "$path"
    fi
}

_pj_fzf_select() {
    local envs desc path name selection
    envs=$(_pj_list_envs)
    [[ -z "$envs" ]] && { echo "错误: 没有找到任何环境，使用 'pj -a <name>' 创建新环境"; return 1; }

    selection=$(while IFS= read -r name; do
        desc=$(_pj_get_description "$name")
        path=$(_pj_get_path "$name")
        printf "%-20s %-80s %s\n" "$name" "$(_pj_truncate_path "$path")" "$desc"
    done <<< "$envs" | fzf --height=40% --layout=reverse --header="Select Project Environment")

    [[ -n "$selection" ]] && awk '{print $1}' <<< "$selection"
}

_pj_switch() {
    local name="$1"
    local env_file="$_PJ_DIR/${name}.env.sh"

    if [[ ! -f "$env_file" ]]; then
        echo "错误: 环境不存在: $name"
        echo "使用 'pj -a $name' 创建新环境"
        return 1
    fi

    # 清除所有 PJ_ 开头的环境变量
    unset "${!PJ_@}"

    # shellcheck source=/dev/null
    source "$env_file"
    echo "已切换到环境: $name"
}

_pj_exec() {
    local label="$1"

    [[ -z "$PJ_CMDS" || ! -f "$PJ_CMDS" ]] && return

    local cmd line
    if [[ -n "$label" ]]; then
        # 按标签直接执行
        cmd=$(grep "^$label:" "$PJ_CMDS" | head -1 | cut -d: -f2-)
        if [[ -z "$cmd" ]]; then
            echo "错误: 未找到标签 '$label'"
            return 1
        fi
    else
        # fzf 选择，格式化显示
        local selection
        selection=$(awk -F: '{printf "%-15s %s\n", $1, $2}' "$PJ_CMDS" | fzf --height=40% --layout=reverse --header="Select Command")
        cmd=$(echo "$selection" | awk '{$1=""; print substr($0,2)}')
    fi

    if [[ -n "$cmd" ]]; then
        # LRU: 移到最前面（保留标签）
        line=$(grep -n ":$cmd$" "$PJ_CMDS" | cut -d: -f1)
        if [[ -n "$line" ]]; then
            local full_line
            full_line=$(sed -n "${line}p" "$PJ_CMDS")
            sed -i "${line}d" "$PJ_CMDS"
            sed -i "1i $full_line" "$PJ_CMDS"
        fi

        echo "执行: $cmd"
        eval "$cmd"
    fi
}

_pj_save() {
    local name="$1"
    local env_file="$_PJ_DIR/${name}.env.sh"
    local current_dir template

    if [[ -z "$name" ]]; then
        echo "错误: 请指定环境名称"
        echo "用法: pj -a <name>"
        return 1
    fi

    current_dir="$(pwd)"
    template="$_PJ_LIB/pj.env.sh"

    if [[ ! -f "$template" ]]; then
        echo "错误: 模板文件不存在: $template"
        return 1
    fi

    # 使用 bash 字符串替换避免 sed 特殊字符问题
    local content
    content=$(<"$template")
    content="${content//\/path\/to\/project/$current_dir}"
    content="${content//myproject/$name}"
    echo "$content" > "$env_file"

    echo "已创建环境: $name"
    _pj_switch "$name"
}

_pj_edit() {
    local name="$1"
    local env_file

    if [[ -z "$name" ]]; then
        # 如果在环境中，编辑当前环境；否则 fzf 选择
        if [[ -n "$PJ_NAME" ]]; then
            name="$PJ_NAME"
        else
            name=$(_pj_fzf_select) || return 1
        fi
    fi

    env_file="$_PJ_DIR/${name}.env.sh"

    if [[ ! -f "$env_file" ]]; then
        echo "错误: 环境不存在: $name"
        return 1
    fi

    ${EDITOR:-vim} "$env_file"
}

_pj_savecmd() {
    local label=""

    # 检查是否有 -l 参数
    if [[ "${1:-}" == "-l" && -n "${2:-}" ]]; then
        label="$2"
        shift 2
    fi

    [[ -z "$PJ_CMDS" ]] && { echo "错误: 当前不在任何环境中 (PJ_CMDS 未设置)"; return 1; }

    local cmd
    cmd=$(fc -ln 1 | sed 's/^[[:space:]]*//' | fzf --height=40% --layout=reverse --header="Select Command from History")

    [[ -z "$cmd" ]] && return

    # 如果标签已存在，清空原标签
    if [[ -n "$label" ]]; then
        sed -i "s/^$label:/:/" "$PJ_CMDS"
    fi

    # 检查命令是否已存在
    local line
    line=$(grep -n ":$cmd$" "$PJ_CMDS" | cut -d: -f1 | head -1)

    if [[ -n "$line" ]]; then
        # 命令存在，更新标签
        if [[ -n "$label" ]]; then
            sed -i "${line}s/^[^:]*:/$label:/" "$PJ_CMDS"
            echo "已更新标签: [$label] $cmd"
        else
            echo "命令已存在: $cmd"
        fi
    else
        # 命令不存在，添加新行
        echo "${label:-}:$cmd" >> "$PJ_CMDS"
        [[ -n "$label" ]] && echo "已添加命令: [$label] $cmd" || echo "已添加命令: $cmd"
    fi
}

_pj_delete() {
    local name="$1"

    if [[ -z "$name" ]]; then
        name=$(_pj_fzf_select) || return 1
    fi

    local env_file="$_PJ_DIR/${name}.env.sh"

    if [[ ! -f "$env_file" ]]; then
        echo "错误: 环境不存在: $name"
        return 1
    fi

    rm "$env_file"
    echo "已删除环境: $name"
}

_pj_list() {
    local name desc path
    printf "%-20s %-80s %s\n" "NAME" "PATH" "DESCRIPTION"
    printf "%-20s %-80s %s\n" "----" "----" "-----------"
    while IFS= read -r name; do
        desc=$(_pj_get_description "$name")
        path=$(_pj_get_path "$name")
        printf "%-20s %-80s %s\n" "$name" "$(_pj_truncate_path "$path")" "$desc"
    done < <(_pj_list_envs)
}

pj() {
    _pj_ensure_dirs

    case "${1:-}" in
        --list-envs)
            _pj_list
            ;;
        -e|--edit)
            _pj_edit "${2:-}"
            ;;
        -a|--add)
            _pj_save "${2:-}"
            ;;
        -s|--savecmd)
            _pj_savecmd "${2:-}" "${3:-}"
            ;;
        -c|--cmd)
            _pj_exec "${2:-}"
            ;;
        -d|--delete)
            _pj_delete "${2:-}"
            ;;
        --list-cmds)
            [[ -z "$PJ_CMDS" || ! -f "$PJ_CMDS" ]] && { echo "错误: 当前不在任何环境中"; return 1; }
            awk -F: '{printf "%-15s %s\n", $1, $2}' "$PJ_CMDS"
            ;;
        -h|--help)
            cat << 'EOF'
pj - 项目环境切换器

用法:
    pj              fzf 交互式选择环境
    pj <name>       切换到指定环境
    pj --list-envs  列出所有环境
    pj -e [name]    编辑环境脚本
    pj -d [name]    删除环境
    pj -a <name>    添加当前目录为新环境
    pj -s [-l <label>]  从 history 选择命令保存到 PJ_CMDS
    pj -c [label]   执行命令（指定标签则直接执行，否则 fzf 选择）
    pj --list-cmds  列出当前环境的所有命令

命令格式: label:command
环境脚本目录: ~/.pjs/
EOF
            ;;
        -*)
            echo "错误: 未知选项: $1"
            echo "使用 'pj -h' 查看帮助"
            return 1
            ;;
        "")
            local name
            name=$(_pj_fzf_select) || return 1
            _pj_switch "$name"
            ;;
        *)
            _pj_switch "$1"
            ;;
    esac
}