#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

export HOME="$TEST_DIR/home"
export _PJ_DIR="$HOME/.pjs"
mkdir -p "$HOME" "$_PJ_DIR"

# shellcheck source=pj.sh
source "$SCRIPT_DIR/pj.sh"

HISTORY_FIXTURE=""
FZF_CHOICE=""
fc() {
    printf '%s\n' "$HISTORY_FIXTURE"
}
fzf() {
    local line first=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$first" ]] || first="$line"
        if [[ -n "$FZF_CHOICE" && "$line" == "$FZF_CHOICE" ]]; then
            printf '%s\n' "$line"
            return
        fi
    done
    [[ -z "$FZF_CHOICE" && -n "$first" ]] && printf '%s\n' "$first"
}

echo "=== pj 测试开始 ==="

repo="$TEST_DIR/sample-repo"
mkdir -p "$repo/subdir"
git init -q "$repo"
git -C "$repo" remote add origin git@github.com:example/remote-repo.git
cd "$repo/subdir"

echo -n "1. 按 remote repo 保存带标签命令... "
HISTORY_FIXTURE=$'echo hello\necho building'
FZF_CHOICE="echo building"
pj -s -l build >/dev/null
cmds_file="$_PJ_DIR/remote-repo.pjcmds"
[[ -f "$cmds_file" ]] && grep -Fqx 'build:echo building' "$cmds_file"
echo "OK"

echo -n "2. 保存无标签命令... "
FZF_CHOICE="echo hello"
pj -s >/dev/null
grep -Fqx ':echo hello' "$cmds_file"
echo "OK"

echo -n "3. 同一命令更新标签且不重复... "
FZF_CHOICE="echo building"
pj -s -l compile >/dev/null
grep -Fqx 'compile:echo building' "$cmds_file"
! grep -Fq 'build:echo building' "$cmds_file"
[[ $(grep -Fc 'echo building' "$cmds_file") -eq 1 ]]
echo "OK"

echo -n "4. 按标签执行并更新 LRU... "
result=$(pj -c compile)
[[ "$result" == *"building"* ]]
[[ $(head -1 "$cmds_file") == 'compile:echo building' ]]
echo "OK"

echo -n "5. fzf 选择执行无标签命令... "
FZF_CHOICE=':echo hello'
result=$(pj -c)
[[ "$result" == *"hello"* ]]
[[ $(head -1 "$cmds_file") == ':echo hello' ]]
echo "OK"

echo -n "6. 无 origin 时使用 Git 根目录名... "
local_repo="$TEST_DIR/local-repo"
git init -q "$local_repo"
cd "$local_repo"
HISTORY_FIXTURE='echo local'
FZF_CHOICE='echo local'
pj -s >/dev/null
grep -Fqx ':echo local' "$_PJ_DIR/local-repo.pjcmds"
echo "OK"

echo -n "7. 自动迁移仓库根目录的旧 .pjcmds... "
root_legacy="$TEST_DIR/root-legacy"
git init -q "$root_legacy"
git -C "$root_legacy" remote add origin https://example.com/team/root-migrated.git
printf 'legacy:echo root-legacy\n' > "$root_legacy/.pjcmds"
cd "$root_legacy"
result=$(pj -c legacy)
[[ "$result" == *"root-legacy"* ]]
[[ ! -e "$root_legacy/.pjcmds" ]]
grep -Fqx 'legacy:echo root-legacy' "$_PJ_DIR/root-migrated.pjcmds"
echo "OK"

echo -n "8. 自动迁移旧项目名的共享命令文件... "
shared_legacy="$TEST_DIR/shared-legacy"
git init -q "$shared_legacy"
git -C "$shared_legacy" remote add origin git@example.com:team/shared-migrated.git
printf '#!/usr/bin/env bash\n# Project: old-project\n# Path: %s\n' "$shared_legacy" > "$_PJ_DIR/old-project.env.sh"
printf 'shared:echo shared-legacy\n' > "$_PJ_DIR/old-project.pjcmds"
cd "$shared_legacy"
result=$(pj -c shared)
[[ "$result" == *"shared-legacy"* ]]
[[ ! -e "$_PJ_DIR/old-project.pjcmds" ]]
grep -Fqx 'shared:echo shared-legacy' "$_PJ_DIR/shared-migrated.pjcmds"
echo "OK"

echo -n "9. 迁移时合并已有命令并去重... "
merge_repo="$TEST_DIR/merge-repo"
git init -q "$merge_repo"
printf 'new:echo new\n:same\n' > "$_PJ_DIR/merge-repo.pjcmds"
printf 'old:echo old\n:same\n' > "$merge_repo/.pjcmds"
cd "$merge_repo"
result=$(pj -c old)
[[ "$result" == *"old"* ]]
[[ ! -e "$merge_repo/.pjcmds" ]]
grep -Fqx 'new:echo new' "$_PJ_DIR/merge-repo.pjcmds"
[[ $(grep -Fxc ':same' "$_PJ_DIR/merge-repo.pjcmds") -eq 1 ]]
echo "OK"

echo -n "10. 非 Git 目录拒绝运行... "
outside="$TEST_DIR/outside"
mkdir -p "$outside"
cd "$outside"
if result=$(pj -c 2>&1); then
    echo "FAIL"
    exit 1
elif [[ "$result" == *'不在 Git 仓库'* ]]; then
    echo "OK"
else
    echo "FAIL"
    exit 1
fi

echo -n "11. 旧命令入口已下线... "
cd "$repo"
if result=$(pj -a old 2>&1); then
    echo "FAIL"
    exit 1
elif [[ "$result" == *'未知选项'* ]]; then
    echo "OK"
else
    echo "FAIL"
    exit 1
fi
if result=$(pj --migrate 2>&1); then
    echo "FAIL"
    exit 1
elif [[ "$result" == *'未知选项'* ]]; then
    echo "OK"
else
    echo "FAIL"
    exit 1
fi

echo -n "12. 帮助只展示新入口... "
help=$(pj -h)
[[ "$help" == *'pj -s'* && "$help" == *'pj -c'* ]]
[[ "$help" != *'--list-envs'* && "$help" != *'--migrate'* ]]
echo "OK"

echo "=== 所有测试通过 ==="
