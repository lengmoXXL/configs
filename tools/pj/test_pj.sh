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
cmds_file="$_PJ_DIR/github.com__example__remote-repo.pjcmds"
[[ -f "$cmds_file" ]] && grep -Fqx 'build:echo building' "$cmds_file"
echo "OK"

echo -n "2. 保存无标签命令... "
FZF_CHOICE="echo hello"
pj -s >/dev/null
grep -Fqx ':echo hello' "$cmds_file"
echo "OK"

echo -n "3. 兼容 noclobber 和交互式 mv 包装... "
FZF_CHOICE="echo building"
set -o noclobber
mv() {
    return 97
}
result=$(pj -s -l compile)
grep -Fqx 'compile:echo building' "$cmds_file"
! grep -Fq 'build:echo building' "$cmds_file"
[[ $(grep -Fc 'echo building' "$cmds_file") -eq 1 ]]
result=$(pj -c compile)
[[ "$result" == *"building"* ]]
[[ $(head -1 "$cmds_file") == 'compile:echo building' ]]
! compgen -G "$_PJ_DIR/.pjcmds.*" >| /dev/null
unset -f mv
set +o noclobber
echo "OK"

echo -n "4. fzf 选择执行无标签命令... "
FZF_CHOICE=':echo hello'
result=$(pj -c)
[[ "$result" == *"hello"* ]]
[[ $(head -1 "$cmds_file") == ':echo hello' ]]
echo "OK"

echo -n "5. SSH 和 HTTPS origin 使用同一仓库标识... "
git -C "$repo" remote set-url origin https://github.com/example/remote-repo.git
result=$(pj -c compile)
[[ "$result" == *"building"* ]]
[[ $(find "$_PJ_DIR" -name '*remote-repo.pjcmds' | wc -l) -eq 1 ]]
echo "OK"

echo -n "6. 无 origin 时使用 Git 根目录绝对路径... "
local_repo="$TEST_DIR/local-repo"
git init -q "$local_repo"
cd "$local_repo"
HISTORY_FIXTURE='echo local'
FZF_CHOICE='echo local'
pj -s >/dev/null
local_cmds_file="$_PJ_DIR/local${local_repo//\//__}.pjcmds"
grep -Fqx ':echo local' "$local_cmds_file"
echo "OK"

echo -n "7. 不同组织的同名仓库使用不同文件... "
collision_a="$TEST_DIR/collision-a"
collision_b="$TEST_DIR/collision-b"
git init -q "$collision_a"
git init -q "$collision_b"
git -C "$collision_a" remote add origin git@github.com:team-a/shared.git
git -C "$collision_b" remote add origin git@github.com:team-b/shared.git
printf 'alpha:echo alpha\n' > "$_PJ_DIR/github.com__team-a__shared.pjcmds"
printf 'beta:echo beta\n' > "$_PJ_DIR/github.com__team-b__shared.pjcmds"
cd "$collision_a"
result=$(pj -c alpha)
[[ "$result" == *"alpha"* ]]
cd "$collision_b"
result=$(pj -c beta)
[[ "$result" == *"beta"* ]]
echo "OK"

echo -n "8. 非 Git 目录拒绝运行... "
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

echo -n "9. 旧命令入口已下线... "
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

echo -n "10. 帮助只展示新入口... "
help=$(pj -h)
[[ "$help" == *'pj -s'* && "$help" == *'pj -c'* ]]
[[ "$help" != *'--list-envs'* && "$help" != *'--migrate'* ]]
echo "OK"

echo "=== 所有测试通过 ==="
