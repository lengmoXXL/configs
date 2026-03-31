#!/bin/bash
# 添加新词到 ds-pinyin-lsp 词典

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
        echo "添加新词..."
        python3 -c "
import sqlite3
conn = sqlite3.connect('$DICT_DB')
cursor = conn.cursor()
cursor.execute('INSERT INTO dict (pinyin, hanzi, priority) VALUES (?, ?, 0)', ('$pinyin', '$word'))
conn.commit()
print('已添加')
"
    fi
}

if [[ -n "$1" ]]; then
    add_word "$1"
else
    echo "用法: $0 <中文词>"
    echo "示例: $0 羁绊"
fi