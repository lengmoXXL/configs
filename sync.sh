#!/bin/bash
# 遍历 install/ 下所有安装脚本，更新已安装的工具与配置
# 每个脚本在 UPDATE=1 下：未安装则跳过；已安装则对比版本/内容，按需更新

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export UPDATE=1

failed=()
for script in "$ROOT"/install/*.sh "$ROOT"/install/compiler/*.sh \
    "$ROOT"/install/lsp/*.sh "$ROOT"/install/skill/*.sh; do
    [[ -f "$script" ]] || continue
    echo ""
    echo "==> ${script#"$ROOT"/}"
    if ! "$script"; then
        failed+=("${script#"$ROOT"/}")
    fi
done

for script in "$ROOT"/install/*.py; do
    echo ""
    echo "==> ${script#"$ROOT"/}"
    if ! python3 "$script"; then
        failed+=("${script#"$ROOT"/}")
    fi
done

echo ""
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "sync 完成，以下脚本失败:"
    printf '  %s\n' "${failed[@]}"
    exit 1
fi
echo "sync 完成"
