#!/bin/bash
# ds-pinyin-lsp 词典管理

set -e

PYTHON_DIR="${HOME}/.local/python3.11"
DATA_DIR="$HOME/.local/share/ds-pinyin-lsp"
DICT_DB="$HOME/.local/share/ds-pinyin-lsp/dict.db3"
PROXY="${GITHUB_PROXY:-https://gh-proxy.com/}"
DICT_URL="${PROXY}https://github.com/iamcco/ds-pinyin-lsp/releases/download/v0.4.0/dict.db3.zip"

# 检查 Python 环境
if [[ ! -x "$PYTHON_DIR/bin/python3" ]]; then
    echo "错误: Python 3.11 未安装，请先运行 ../sys/install-python.sh"
    exit 1
fi

# 使用本地 Python 环境
export PATH="$PYTHON_DIR/bin:$PATH"

ensure_dict_db() {
    if [[ -f "$DICT_DB" ]]; then
        return 0
    fi

    echo "词典数据库不存在，开始安装..."
    mkdir -p "$DATA_DIR"

    local tmp_zip
    tmp_zip=$(mktemp /tmp/dict.db3.XXXXXX.zip)
    trap 'rm -f "$tmp_zip"' RETURN

    curl -fL "$DICT_URL" -o "$tmp_zip"
    unzip -o "$tmp_zip" -d "$DATA_DIR/"

    if [[ ! -f "$DICT_DB" ]]; then
        echo "错误: 词典安装失败: $DICT_DB"
        exit 1
    fi

    echo "词典安装完成: $DICT_DB"
}

# 检查 pypinyin
if ! "$PYTHON_DIR/bin/python3" -c "import pypinyin" 2>/dev/null; then
    echo "安装 pypinyin..."
    "$PYTHON_DIR/bin/pip3" install pypinyin --quiet
fi

add_word() {
    local word="$1"
    local pinyin

    # 获取拼音（不带声调，无空格）
    pinyin=$(python3 -c "
import pypinyin
word = '$word'
result = pypinyin.lazy_pinyin(word, style=pypinyin.Style.NORMAL)
print(''.join(result))
")

    if [[ -z "$pinyin" ]]; then
        echo "错误: 无法获取拼音"
        return 1
    fi

    echo "词: $word"
    echo "拼音: $pinyin"
    echo ""

    # 显示同拼音的所有候选词及建议权重
    python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute(
    'SELECT hanzi, priority FROM dict WHERE pinyin = ? ORDER BY priority DESC, hanzi ASC LIMIT 10',
    ('$pinyin',)
)
rows = cursor.fetchall()
if not rows:
    print('同拼音候选词: (无)')
    print()
    print('建议权重: 10000 (排首位)')
else:
    print('同拼音候选词 (按权重降序):')
    max_pri = rows[0][1]
    second_pri = rows[1][1] if len(rows) > 1 else 0
    target_rank = None
    target_priority = None
    for idx, (hanzi, priority) in enumerate(rows, 1):
        marker = ''
        if hanzi == '$word':
            marker = ' *'
            target_rank = idx
            target_priority = priority
        print(f'  {idx}. {hanzi}\tpriority={priority}{marker}')
    print()
    if '$word' in [r[0] for r in rows]:
        print(f'当前词 \"$word\" 排第 {target_rank} 位，权重 {target_priority}')
        if target_rank == 1:
            print('已是首位，无需调整')
        else:
            suggest = max_pri + 1000
            print(f'想排首位: 建议 {suggest} (当前首位 {max_pri})')
    else:
        print('建议权重:')
        if max_pri < 10000:
            print(f'  想排首位: {max_pri + 1000}')
        else:
            print(f'  想排首位: {max_pri + 1000}')
        if second_pri > 0:
            print(f'  想排第二: {(max_pri + second_pri) // 2}')
"

    # 检查是否已存在
    exists=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM dict WHERE hanzi = ?', ('$word',))
print(cursor.fetchone()[0])
")

    if [[ "$exists" -gt 0 ]]; then
        # 获取当前信息
        current_info=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT pinyin, priority FROM dict WHERE hanzi = ?', ('$word',))
pinyin, priority = cursor.fetchone()
print(f'{pinyin}|{priority}')
")
        current_pinyin="${current_info%%|*}"
        current_priority="${current_info##*|}"

        echo ""
        echo "当前: pinyin=$current_pinyin, priority=$current_priority"

        update_pinyin=""
        update_priority=""

        # 问是否更新拼音
        if [[ "$current_pinyin" != "$pinyin" ]]; then
            echo "新拼音: $pinyin"
            read -p "更新拼音? [y/N] " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                update_pinyin="$pinyin"
            fi
        fi

        # 问是否更新权重
        read -p "更新权重? (输入新权重或直接回车跳过) " new_priority
        if [[ -n "$new_priority" ]]; then
            if [[ "$new_priority" =~ ^-?[0-9]+$ ]]; then
                update_priority="$new_priority"
            else
                echo "权重必须是整数，跳过权重更新"
            fi
        fi

        # 确认更改
        if [[ -n "$update_pinyin" || -n "$update_priority" ]]; then
            echo ""
            echo "即将更新 '$word':"
            [[ -n "$update_pinyin" ]] && echo "  pinyin: $current_pinyin → $update_pinyin"
            [[ -n "$update_priority" ]] && echo "  priority: $current_priority → $update_priority"
            read -p "确认? [y/N] " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
if '$update_pinyin':
    cursor.execute('UPDATE dict SET pinyin = ? WHERE hanzi = ?', ('$update_pinyin', '$word'))
if '$update_priority':
    cursor.execute('UPDATE dict SET priority = ? WHERE hanzi = ?', ($update_priority, '$word'))
conn.commit()
print('已更新')
"
            else
                echo "已取消"
            fi
        else
            echo "无更改"
        fi
    else
        echo ""
        read -p "添加新词，输入权重 (直接回车使用默认 0): " priority
        if [[ -z "$priority" ]]; then
            priority=0
        elif ! [[ "$priority" =~ ^-?[0-9]+$ ]]; then
            echo "权重必须是整数，使用默认值 0"
            priority=0
        fi

        read -p "确认添加 '$word' (权重=$priority)? [Y/n] " choice
        if [[ "$choice" =~ ^[Nn]$ ]]; then
            echo "已跳过"
        else
            python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('INSERT INTO dict (pinyin, hanzi, priority) VALUES (?, ?, ?)', ('$pinyin', '$word', $priority))
conn.commit()
print(f'已添加: $word ($pinyin) priority=$priority')
"
        fi
    fi
}

delete_word() {
    local word="$1"

    # 检查是否存在
    exists=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM dict WHERE hanzi = ?', ('$word',))
print(cursor.fetchone()[0])
")

    if [[ "$exists" -eq 0 ]]; then
        echo "词不存在: $word"
        return 1
    fi

    # 获取现有拼音
    pinyin=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT pinyin FROM dict WHERE hanzi = ?', ('$word',))
print(cursor.fetchone()[0])
")

    echo "词: $word"
    echo "拼音: $pinyin"
    read -p "确认删除? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('DELETE FROM dict WHERE hanzi = ?', ('$word',))
conn.commit()
print('已删除')
"
    else
        echo "已跳过"
    fi
}

query_pinyin() {
    local pinyin="$1"

    python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute(
    'SELECT hanzi, priority FROM dict WHERE pinyin = ? ORDER BY priority DESC, hanzi ASC',
    ('$pinyin',)
)
rows = cursor.fetchall()
if not rows:
    print('未找到拼音候选: $pinyin')
else:
    print('拼音: $pinyin')
    print('候选词 (按权重降序):')
    for idx, (hanzi, priority) in enumerate(rows, 1):
        print(f'{idx}. {hanzi}\tpriority={priority}')
"
}

set_word_priority() {
    local word="$1"
    local priority="$2"

    if [[ ! "$priority" =~ ^-?[0-9]+$ ]]; then
        echo "错误: priority 必须是整数"
        return 1
    fi

    exists=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM dict WHERE hanzi = ?', ('$word',))
print(cursor.fetchone()[0])
")

    if [[ "$exists" -eq 0 ]]; then
        echo "词不存在: $word"
        return 1
    fi

    python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute(
    'UPDATE dict SET priority = ? WHERE hanzi = ?',
    ($priority, '$word')
)
conn.commit()
cursor.execute(
    'SELECT pinyin, hanzi, priority FROM dict WHERE hanzi = ? LIMIT 1',
    ('$word',)
)
pinyin, hanzi, priority = cursor.fetchone()
print(f'已更新: {hanzi} ({pinyin}) priority={priority}')
"
}

usage() {
    echo "用法: $0 [--install] | [-d] <中文词> | [--query-pinyin <拼音>] | [--set-priority <中文词> <权重>]"
    echo "  -h, --help: 显示帮助"
    echo "  --install: 仅安装或更新词典数据库"
    echo "  不带参数: 添加或更新词条"
    echo "  -d: 删除词条"
    echo "  --query-pinyin: 查询某个拼音的候选词和权重"
    echo "  --set-priority: 修改某个中文词的权重"
    echo ""
    echo "示例:"
    echo "  $0 --install # 安装词典"
    echo "  $0 --query-pinyin ni"
    echo "  $0 --set-priority 你 20000000"
    echo "  $0 羁绊    # 添加或更新"
    echo "  $0 -d 羁绊 # 删除"
}

if [[ -z "$1" ]]; then
    usage
    exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$1" == "--install" ]]; then
    ensure_dict_db
    exit 0
fi

ensure_dict_db

if [[ "$1" == "--query-pinyin" ]]; then
    if [[ -z "$2" ]]; then
        usage
        exit 1
    fi
    query_pinyin "$2"
elif [[ "$1" == "--set-priority" ]]; then
    if [[ -z "$2" || -z "$3" ]]; then
        usage
        exit 1
    fi
    set_word_priority "$2" "$3"
elif [[ "$1" == "-d" ]]; then
    if [[ -z "$2" ]]; then
        usage
        exit 1
    fi
    delete_word "$2"
else
    add_word "$1"
fi
