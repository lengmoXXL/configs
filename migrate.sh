#!/bin/bash
# 迁移脚本: 将本仓库 clone 的 origin 从 configs 切换到 mytoolsets
# 用法: bash migrate.sh
# 幂等: 已指向 mytoolsets 时仅执行 fetch + 快进

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

NEW_REPO="lengmoXXL/mytoolsets"

current="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "$current" ]]; then
    echo "错误: 未配置 origin remote" >&2
    exit 1
fi

# 沿用现有的 ssh/https 协议
if [[ "$current" == http* ]]; then
    new_url="https://github.com/${NEW_REPO}.git"
else
    new_url="git@github.com:${NEW_REPO}.git"
fi

if [[ "$current" == *mytoolsets* ]]; then
    echo "origin 已指向 mytoolsets: $current"
else
    git remote set-url origin "$new_url"
    echo "origin 已切换: $current -> $new_url"
fi

git fetch origin --prune

if ! git rev-parse --verify origin/main &>/dev/null; then
    echo "错误: 新远端没有 main 分支，请确认 mytoolsets 已完成内容迁移" >&2
    exit 1
fi

branch="$(git branch --show-current)"
if [[ "$branch" != "main" ]]; then
    echo "提示: 当前在 $branch 分支，仅切换 remote，未切换分支"
    exit 0
fi

if git merge-base --is-ancestor HEAD origin/main; then
    git merge --ff-only origin/main
    echo "已快进到 origin/main"
elif [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]]; then
    echo "已是最新"
else
    echo "警告: 本地 main 与新远端 main 历史分叉，未自动合并" >&2
    echo "请手动处理: git status 查看后 rebase 或 reset 到 origin/main" >&2
    exit 1
fi
