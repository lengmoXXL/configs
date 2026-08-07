#!/bin/bash
# 删除当前 Git 仓库中已合并到主分支的本地分支
# 主分支判定：优先 origin/HEAD 指向（本地缺失时以其远程跟踪分支为基准），其次本地 main，再次本地 master

set -uo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "错误: 当前目录不在 Git 仓库内" >&2
    exit 1
fi

origin_head=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
if [[ -n "$origin_head" ]]; then
    protected="${origin_head#origin/}"
    if git show-ref --verify --quiet "refs/heads/$protected"; then
        base="$protected"
    else
        base="$origin_head"
    fi
elif git show-ref --verify --quiet refs/heads/main; then
    base="main"
    protected="main"
elif git show-ref --verify --quiet refs/heads/master; then
    base="master"
    protected="master"
else
    echo "错误: 无法确定主分支（origin/HEAD、main、master 均不存在）" >&2
    exit 1
fi

current=$(git branch --show-current)
deleted=0
while read -r branch; do
    [[ "$branch" == "$protected" || "$branch" == "$current" ]] && continue
    if git branch -D "$branch" >/dev/null 2>&1; then
        echo "已删除: $branch"
        deleted=$((deleted + 1))
    else
        echo "跳过: $branch（删除失败，可能已检出到其它 worktree）" >&2
    fi
done < <(git branch --merged "$base" --format='%(refname:short)')

if [[ $deleted -eq 0 ]]; then
    echo "没有已合并到 $base 的其它分支"
else
    echo "共删除 $deleted 个分支（基准: $base）"
fi
