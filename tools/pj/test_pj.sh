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

# 9. 测试环境不存在报错
echo -n "9. 环境不存在报错... "
if pj nonexistent 2>&1 | grep -q "环境不存在"; then
    echo "OK"
else
    echo "FAIL"
    exit 1
fi

# 10. 测试无冒号前缀命令（LRU）
echo -n "10. 无冒号命令 LRU... "
echo "echo plain" > "$PJ_CMDS"
echo "test:echo test" >> "$PJ_CMDS"
pj -c test >/dev/null
result=$(grep -n "echo plain" "$PJ_CMDS" | cut -d: -f1)
[[ "$result" == "2" ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 11. 测试正则特殊字符命令
echo -n "11. 正则特殊字符命令... "
echo "spec:echo 'a.b*c[d]e'" > "$PJ_CMDS"
pj -c spec >/dev/null
result=$(grep -F "echo 'a.b*c[d]e'" "$PJ_CMDS")
[[ -n "$result" ]] && echo "OK" || { echo "FAIL"; exit 1; }

# 12. 测试帮助
echo -n "12. 帮助显示... "
result=$(pj -h)
[[ "$result" == *"项目环境切换器"* ]] && echo "OK" || { echo "FAIL"; exit 1; }

echo ""
echo "=== 所有测试通过 ==="