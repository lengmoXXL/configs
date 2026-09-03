#!/usr/bin/env bash
# Sync provider API keys with OSS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT/.secrets}"
OSS_BUCKET="${SECRETS_OSS_BUCKET:-lengmo-secrets}"
OSS_PREFIX="${SECRETS_OSS_PREFIX:-configs}"
OSS_ENDPOINT="${SECRETS_OSS_ENDPOINT:-oss-cn-beijing.aliyuncs.com}"
OSS_URI="${SECRETS_OSS_URI:-oss://$OSS_BUCKET/$OSS_PREFIX}"
OSS_CONFIG_FILE="${SECRETS_OSS_CONFIG:-$SECRETS_DIR/ossutilconfig}"
AI_PROVIDERS_SECRET="ai-providers.json"
AI_PROVIDERS_PATH="$SECRETS_DIR/$AI_PROVIDERS_SECRET"

usage() {
    cat <<EOF
Usage: $0 <init|ls|push|pull>

Commands:
  init     Interactively create .secrets/ossutilconfig and ai-providers.json.
  ls       Show .secrets/$AI_PROVIDERS_SECRET path.
  push     Upload .secrets/$AI_PROVIDERS_SECRET to OSS.
  pull     Merge $AI_PROVIDERS_SECRET from OSS into .secrets (local keys win).

Environment:
  SECRETS_DIR          Local secrets directory. Default: $SECRETS_DIR
  SECRETS_OSS_BUCKET   OSS bucket. Default: $OSS_BUCKET
  SECRETS_OSS_PREFIX   OSS prefix. Default: $OSS_PREFIX
  SECRETS_OSS_ENDPOINT OSS endpoint. Default: $OSS_ENDPOINT
  SECRETS_OSS_URI      OSS prefix URI. Default: $OSS_URI
  SECRETS_OSS_CONFIG   ossutil config file. Default: $OSS_CONFIG_FILE
EOF
}

require_ossutil() {
    if ! command -v ossutil >/dev/null 2>&1; then
        echo "错误: 缺少 ossutil" >&2
        echo "请先运行: $ROOT/install/ossutil.sh" >&2
        exit 1
    fi
}

has_oss_config_credentials() {
    [[ -f "$OSS_CONFIG_FILE" ]] &&
        grep -Eq '^accessKeyId=.+$' "$OSS_CONFIG_FILE" &&
        grep -Eq '^accessKeySecret=.+$' "$OSS_CONFIG_FILE"
}

require_oss_config_credentials() {
    if ! has_oss_config_credentials; then
        echo "错误: $OSS_CONFIG_FILE 未填写 accessKeyId/accessKeySecret" >&2
        echo "请先运行: $0 init 并填写凭据" >&2
        exit 1
    fi
}

ai_providers_object_uri() {
    printf '%s/%s\n' "${OSS_URI%/}" "$AI_PROVIDERS_SECRET"
}

init_secrets() {
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"

    if [[ ! -f "$SECRETS_DIR/ossutilconfig" ]]; then
        local access_key_id="" access_key_secret=""
        read -rp "accessKeyId (留空跳过): " access_key_id
        if [[ -n "$access_key_id" ]]; then
            read -rsp "accessKeySecret: " access_key_secret
            echo
        fi
        cat > "$SECRETS_DIR/ossutilconfig" <<EOF
[default]
language=CH
accessKeyId=$access_key_id
accessKeySecret=$access_key_secret
endpoint=$OSS_ENDPOINT
region=cn-beijing
EOF
        chmod 600 "$SECRETS_DIR/ossutilconfig"
        echo "created: $SECRETS_DIR/ossutilconfig"
        if [[ -z "$access_key_id" ]]; then
            echo "  未填写凭据，请稍后补填"
        fi
    else
        echo "exists: $SECRETS_DIR/ossutilconfig"
    fi

    if [[ ! -f "$AI_PROVIDERS_PATH" ]]; then
        local bailian_token=""
        read -rp "bailian-token-plan API key (留空跳过): " bailian_token
        cat > "$AI_PROVIDERS_PATH" <<EOF
{
  "bailian-token-plan": "$bailian_token"
}
EOF
        chmod 600 "$AI_PROVIDERS_PATH"
        echo "created: $AI_PROVIDERS_PATH"
    else
        echo "exists: $AI_PROVIDERS_PATH"
    fi
}

push_secrets() {
    if [[ $# -gt 0 ]]; then
        usage >&2
        exit 1
    fi

    require_ossutil
    require_oss_config_credentials

    if [[ ! -f "$AI_PROVIDERS_PATH" ]]; then
        echo "错误: 缺少 $AI_PROVIDERS_PATH" >&2
        exit 1
    fi

    ossutil cp "$AI_PROVIDERS_PATH" "$(ai_providers_object_uri)" --no-progress --force --endpoint "$OSS_ENDPOINT" --config-file "$OSS_CONFIG_FILE"
}

pull_secrets() {
    if [[ $# -gt 0 ]]; then
        usage >&2
        exit 1
    fi

    require_ossutil
    require_oss_config_credentials

    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"

    local tmp_remote
    tmp_remote="$(mktemp)"
    trap 'rm -f "$tmp_remote"' RETURN

    ossutil cp "$(ai_providers_object_uri)" "$tmp_remote" --no-progress --force --endpoint "$OSS_ENDPOINT" --config-file "$OSS_CONFIG_FILE"
    # JSON key 级合并：远端补充缺失 key，本地已有 key 不覆盖
    python3 - "$AI_PROVIDERS_PATH" "$tmp_remote" <<'EOF'
import json, os, sys

local_path, remote_path = sys.argv[1], sys.argv[2]

local = {}
if os.path.exists(local_path):
    with open(local_path, encoding="utf-8") as fh:
        local = json.load(fh)

with open(remote_path, encoding="utf-8") as fh:
    remote = json.load(fh)

merged = {**remote, **local}
added = sorted(set(remote) - set(local))

with open(local_path, "w", encoding="utf-8") as fh:
    json.dump(merged, fh, ensure_ascii=False, indent=2)
    fh.write("\n")

print("新增 key: " + ", ".join(added) if added else "无新增 key")
EOF
    chmod 600 "$AI_PROVIDERS_PATH"
}

command="${1:-}"
if [[ $# -gt 0 ]]; then
    shift
fi
case "$command" in
    init)
        if [[ $# -gt 0 ]]; then
            usage >&2
            exit 1
        fi
        init_secrets
        ;;
    ls)
        if [[ $# -gt 0 ]]; then
            usage >&2
            exit 1
        fi
        printf '%s\n' "$AI_PROVIDERS_PATH"
        ;;
    push)
        push_secrets "$@"
        ;;
    pull)
        pull_secrets "$@"
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
