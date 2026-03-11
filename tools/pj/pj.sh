#!/usr/bin/env bash

_PJ_DIR="${HOME}/.pjs"
_PJ_LIB="${HOME}"

_pj_ensure_dirs() {
    mkdir -p "$_PJ_DIR"
    mkdir -p "$_PJ_LIB"
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

_pj_fzf_select() {
    local envs desc path name selection
    envs=$(_pj_list_envs)
    [[ -z "$envs" ]] && { echo "错误: 没有找到任何环境，使用 'pj -a <name>' 创建新环境"; return 1; }

    selection=$(while IFS= read -r name; do
        desc=$(_pj_get_description "$name")
        path=$(_pj_get_path "$name")
        printf "%s\t%s\t%s\n" "$name" "$desc" "$path"
    done <<< "$envs" | fzf --height=40% --layout=reverse --header="Select Project Environment" --with-nth=1,2,3 --delimiter='\t')

    [[ -n "$selection" ]] && cut -f1 <<< "$selection"
}

_pj_switch() {
    local name="$1"
    local env_file="$_PJ_DIR/${name}.env.sh"

    if [[ ! -f "$env_file" ]]; then
        echo "错误: 环境不存在: $name"
        echo "使用 'pj -a $name' 创建新环境"
        return 1
    fi

    # shellcheck source=/dev/null
    source "$env_file"

    if declare -f switch &>/dev/null; then
        switch
        echo "已切换到环境: $name"
    else
        echo "错误: 环境脚本缺少 switch 函数: $env_file"
        return 1
    fi
}

_pj_exec() {
    local cmd

    [[ -z "$PJ_CMDS" || ! -f "$PJ_CMDS" ]] && return

    cmd=$(cat "$PJ_CMDS" | fzf --height=40% --layout=reverse --header="Select Command")

    if [[ -n "$cmd" ]]; then
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

    sed "s|/path/to/project|$current_dir|g; s/myproject/$name/g" "$template" > "$env_file"

    echo "已创建环境: $name"
    echo "编辑配置: pj -e $name"
}

_pj_edit() {
    local name="$1"
    local env_file

    if [[ -z "$name" ]]; then
        name=$(_pj_fzf_select) || return 1
    fi

    env_file="$_PJ_DIR/${name}.env.sh"

    if [[ ! -f "$env_file" ]]; then
        echo "错误: 环境不存在: $name"
        return 1
    fi

    ${EDITOR:-vim} "$env_file"
}

_pj_savecmd() {
    local cmd

    [[ -z "$PJ_CMDS" ]] && { echo "错误: 当前不在任何环境中 (PJ_CMDS 未设置)"; return 1; }

    cmd=$(fc -ln 1 | fzf --height=40% --layout=reverse --header="Select Command from History")

    [[ -z "$cmd" ]] && return

    echo "$cmd" >> "$PJ_CMDS"
    echo "已添加命令: $cmd"
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
    printf "%-15s %-30s %s\n" "NAME" "DESCRIPTION" "PATH"
    printf "%-15s %-30s %s\n" "----" "-----------" "----"
    while IFS= read -r name; do
        desc=$(_pj_get_description "$name")
        path=$(_pj_get_path "$name")
        printf "%-15s %-30s %s\n" "$name" "$desc" "$path"
    done < <(_pj_list_envs)
}

pj() {
    _pj_ensure_dirs

    case "${1:-}" in
        -l|--list)
            _pj_list
            ;;
        -e|--edit)
            _pj_edit "${2:-}"
            ;;
        -a|--add)
            _pj_save "${2:-}"
            ;;
        -s|--savecmd)
            _pj_savecmd
            ;;
        -c|--cmd)
            _pj_exec
            ;;
        -d|--delete)
            _pj_delete "${2:-}"
            ;;
        -h|--help)
            cat << 'EOF'
pj - 项目环境切换器

用法:
    pj              fzf 交互式选择环境
    pj <name>       切换到指定环境
    pj -l           列出所有环境
    pj -e [name]    编辑环境脚本
    pj -d [name]    删除环境
    pj -a <name>    添加当前目录为新环境
    pj -s           从 history 选择命令保存到 PJ_CMDS
    pj -c           执行当前环境的命令

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