#!/bin/bash
# 安装/更新 doc-research CLI（PDF/EPUB/网页 → Markdown，Markdown → HTML 站点）
# PINNED_COMMIT 固定安装版本；对比远端 HEAD，不一致则提示有更新（需人工更新此常量后重跑）

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/lengmoXXL/doc-research.git}"
PINNED_COMMIT="2d004122b57ac358e95401ed269648f133d6f954"
USE_CN=false
GITHUB_PROXY_PREFIX="https://gh-proxy.com/"

usage() {
    cat << EOF
用法: $0 [-cn] [本地仓库路径]

选项:
  -cn      通过国内代理访问 GitHub

给定本地路径时以 editable 模式安装（本地修改即时生效），跳过远端对比
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -cn)
            USE_CN=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            if [[ -d "$1" && -z "${LOCAL_PATH:-}" ]]; then
                LOCAL_PATH="$1"
            else
                usage
                exit 1
            fi
            ;;
    esac
    shift
done

if ! command -v uv &>/dev/null; then
    echo "错误: 缺少 uv，请先运行 $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/uv.sh" >&2
    exit 1
fi

if [[ -n "${LOCAL_PATH:-}" ]]; then
    uv tool install --force --editable "$LOCAL_PATH"
    echo "Installed doc-research CLI (editable: $LOCAL_PATH)"
    exit 0
fi

if [[ "$USE_CN" == "true" && "$REPO_URL" == https://github.com/* ]]; then
    REPO_URL="${GITHUB_PROXY_PREFIX}${REPO_URL}"
fi

remote_head="$(git ls-remote "$REPO_URL" HEAD | awk '{print $1}')"
if [[ -z "$remote_head" ]]; then
    echo "错误: 无法获取远端 HEAD: $REPO_URL" >&2
    exit 1
fi
if [[ "$remote_head" != "$PINNED_COMMIT" ]]; then
    echo "提示: 远端有新提交 $remote_head（当前固定 $PINNED_COMMIT），确认后更新 PINNED_COMMIT 再装"
fi

uv tool install --force "git+${REPO_URL}@${PINNED_COMMIT}"

echo "Installed doc-research CLI ($PINNED_COMMIT)"
