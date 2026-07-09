#!/usr/bin/env bash
# Sync the local ai-providers secret with OSS.

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
  init     Create .secrets/ossutilconfig template.
  ls       Show .secrets/$AI_PROVIDERS_SECRET path.
  push     Upload .secrets/$AI_PROVIDERS_SECRET to OSS.
  pull     Download $AI_PROVIDERS_SECRET from OSS to .secrets.

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
        echo "请先运行: $ROOT/install/install-ossutil.sh" >&2
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

oss_args() {
    printf '%s\n' --endpoint "$OSS_ENDPOINT" --config-file "$OSS_CONFIG_FILE"
}

ai_providers_object_uri() {
    printf '%s/%s\n' "${OSS_URI%/}" "$AI_PROVIDERS_SECRET"
}

init_secrets() {
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"

    if [[ ! -f "$SECRETS_DIR/ossutilconfig" ]]; then
        cat > "$SECRETS_DIR/ossutilconfig" <<EOF
[default]
language=CH
accessKeyId=
accessKeySecret=
endpoint=$OSS_ENDPOINT
region=cn-beijing
EOF
        chmod 600 "$SECRETS_DIR/ossutilconfig"
        echo "created: $SECRETS_DIR/ossutilconfig"
        echo "  请手动填写 accessKeyId/accessKeySecret"
    else
        echo "exists: $SECRETS_DIR/ossutilconfig"
    fi

    if [[ ! -f "$AI_PROVIDERS_PATH" ]]; then
        cat > "$AI_PROVIDERS_PATH" <<'EOF'
[
  {
    "name": "bailian-token-plan",
    "endpoint": "https://token-plan.cn-beijing.maas.aliyuncs.com/apps/anthropic",
    "apiKey": "",
    "models": {
      "qwen3.7-max": "qwen3.7-max",
      "qwen3.7-plus": "qwen3.7-plus",
      "deepseek-v4-pro": "deepseek-v4-pro",
      "glm-5.2": "glm-5.2"
    }
  }
]
EOF
        chmod 600 "$AI_PROVIDERS_PATH"
        echo "created: $AI_PROVIDERS_PATH"
        echo "  请手动填写 apiKey，并按需调整 models（key 为 ai-models.json 里的别名，value 为 provider 识别的 model id）"
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

    mapfile -t extra_args < <(oss_args)
    ossutil cp "$AI_PROVIDERS_PATH" "$(ai_providers_object_uri)" --no-progress --force "${extra_args[@]}"
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

    mapfile -t extra_args < <(oss_args)
    ossutil cp "$(ai_providers_object_uri)" "$AI_PROVIDERS_PATH" --no-progress --force "${extra_args[@]}"
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
