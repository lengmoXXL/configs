#!/bin/bash
# 安装 opencode 配置（~/.config/opencode/opencode.json）
# provider 全部用官方注册表（models.dev），不做自定义 provider 配置；
# 密钥由 opencode-auth.sh 单独安装

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools" && pwd)/common.sh"

CONFIG_FILE="${HOME}/.config/opencode/opencode.json"

if [[ "${UPDATE:-}" == "1" && ! -d "$(dirname "$CONFIG_FILE")" ]]; then
    echo "未安装，跳过: $CONFIG_FILE"
    exit 0
fi

tmp_config="$(mktemp)"
cat > "$tmp_config" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json"
}
EOF
write_file_if_changed "$CONFIG_FILE" "$tmp_config"
