#!/bin/bash
# ds-pinyin-lsp 词典管理

set -e

DICT_DB="$HOME/.local/share/ds-pinyin-lsp/dict.db3"

if [[ ! -f "$DICT_DB" ]]; then
    echo "错误: 词典数据库不存在: $DICT_DB"
    echo "请先运行 install-ds-pinyin-lsp.sh 安装"
    exit 1
fi

# 检查 pypinyin
if ! python3 -c "import pypinyin" 2>/dev/null; then
    echo "安装 pypinyin..."
    pip3 install pypinyin --quiet
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

    # 检查是否已存在
    exists=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM dict WHERE hanzi = ?', ('$word',))
print(cursor.fetchone()[0])
")

    if [[ "$exists" -gt 0 ]]; then
        # 获取现有拼音
        old_pinyin=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('SELECT pinyin FROM dict WHERE hanzi = ?', ('$word',))
print(cursor.fetchone()[0])
")
        echo "词已存在"
        echo "  现有拼音: $old_pinyin"
        echo "  新拼音:   $pinyin"
        read -p "是否更新? [y/N] " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('UPDATE dict SET pinyin = ? WHERE hanzi = ?', ('$pinyin', '$word'))
conn.commit()
print('已更新')
"
        else
            echo "已跳过"
        fi
    else
        echo "新词"
        echo "  拼音: $pinyin"
        read -p "是否添加? [Y/n] " choice
        if [[ "$choice" =~ ^[Nn]$ ]]; then
            echo "已跳过"
        else
            python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('INSERT INTO dict (pinyin, hanzi, priority) VALUES (?, ?, 0)', ('$pinyin', '$word'))
conn.commit()
print('已添加')
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

usage() {
    echo "用法: $0 [-d] <中文词>"
    echo "  不带参数: 添加或更新词条"
    echo "  -d: 删除词条"
    echo ""
    echo "示例:"
    echo "  $0 羁绊    # 添加或更新"
    echo "  $0 -d 羁绊 # 删除"
}

if [[ -z "$1" ]]; then
    usage
    exit 1
fi

if [[ "$1" == "-d" ]]; then
    if [[ -z "$2" ]]; then
        usage
        exit 1
    fi
    delete_word "$2"
else
    add_word "$1"
fi