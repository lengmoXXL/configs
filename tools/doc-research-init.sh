#!/bin/bash
# 初始化 doc-research 文献调研项目：raw/（原文底稿）、tr/（译文）、dist/（HTML 报告）
# 幂等：已存在的文件不覆盖
# 用法: doc-research-init [目标目录]（默认当前目录）

set -euo pipefail

target="${1:-.}"

mkdir -p "$target/raw" "$target/tr" "$target/dist"

write_if_missing() {
    local path="$1"
    if [[ -f "$path" ]]; then
        echo "已存在，跳过: $path"
        return
    fi
    cat > "$path"
    echo "创建: $path"
}

# .env：交互式填写 DocMind 凭据；已存在则跳过
if [[ -f "$target/.env" ]]; then
    echo "已存在，跳过: $target/.env"
else
    echo "填写阿里云 DocMind 凭据（doc-research parse 使用）:"
    read -r -p "ALIBABA_CLOUD_ACCESS_KEY_ID: " ak_id
    read -r -p "ALIBABA_CLOUD_ACCESS_KEY_SECRET: " ak_secret
    printf 'ALIBABA_CLOUD_ACCESS_KEY_ID=%s\nALIBABA_CLOUD_ACCESS_KEY_SECRET=%s\n' \
        "$ak_id" "$ak_secret" > "$target/.env"
    echo "创建: $target/.env"
fi

write_if_missing "$target/.gitignore" << 'EOF'
.env
.venv/
__pycache__/
EOF

write_if_missing "$target/README.md" << 'EOF'
# 文献调研

流程：收集（原文转 Markdown 底稿入 `raw/`）→ 整理（校对翻译入 `tr/`）→ 报告（`tr/` 渲染
HTML 入 `dist/`）。

## 1. 收集

```bash
doc-research parse <文档路径> -o raw/<slug>   # PDF/EPUB（DocMind）
doc-research fetch <url> -o raw/<slug>        # 网页
```

`<slug>` 命名 `<短名>-<年份>`，如 `kafka-2011`。

## 2. 整理

对照 `raw/<slug>/raw.md` 与原文逐段校对、翻译为中文，写入 `tr/<slug>.md`。

## 3. 报告

```bash
doc-research build tr -o dist
prd dist/index.html   # 本地预览
```
EOF

echo "doc-research 项目已初始化: $target"
