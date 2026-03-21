#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PJ_SCRIPT="$SCRIPT_DIR/pj.sh"

source "$PJ_SCRIPT"

# 测试用的临时目录
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# 模拟环境
export _PJ_DIR="$TEST_DIR/.pjs"
export _PJ_LIB="$TEST_DIR"
PJ_CMDS="$TEST_DIR/.pjcmds"

# 复制模板文件
cp "$SCRIPT_DIR/pj.env.sh" "$TEST_DIR/pj.env.sh"

echo "=== 测试开始 ==="

# 1. 测试创建环境
echo -n "1. 创建环境... "
pj -a testproj >/dev/null
[[ -f "$_PJ_DIR/testproj.env.sh" ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 2. 测试切换环境
echo -n "2. 切换环境... "
pj testproj >/dev/null
[[ "$PJ_NAME" == "testproj" ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 3. 测试列出环境
echo -n "3. 列出环境... "
result=$(pj --list-envs)
[[ "$result" == *"testproj"* ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 4. 测试添加命令
echo -n "4. 添加命令... "
echo ":echo hello" > "$PJ_CMDS"
echo "build:echo building" >> "$PJ_CMDS"
result=$(pj --list-cmds)
[[ "$result" == *"echo hello"* && "$result" == *"echo building"* ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 5. 测试命令含冒号显示正确
echo -n "5. 命令含冒号显示... "
echo "test:echo a:b:c" >> "$PJ_CMDS"
result=$(pj --list-cmds)
[[ "$result" == *"echo a:b:c"* ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 6. 测试按标签执行
echo -n "6. 按标签执行... "
pj -c build >/dev/null
result=$(head -1 "$PJ_CMDS")
[[ "$result" == "build:echo building" ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 7. 测试标签不存在
echo -n "7. 标签不存在报错... "
if pj -c notfound 2>&1 | grep -q "未找到标签"; then
    echo "OK"
else
    echo "FAIL"
    exit 1
fi

# 8. 测试删除环境
echo -n "8. 删除环境... "
pj -d testproj >/dev/null
[[ ! -f "$_PJ_DIR/testproj.env.sh" ]] && echo "OK" || { echo "FAIL"; exit 1; }

echo ""
echo "=== 所有测试通过 ==="