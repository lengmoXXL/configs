#!/usr/bin/env bash
# Sync local .secrets with OSS and install supported secret files.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT/.secrets}"
BACKUP_ROOT="${SECRETS_BACKUP_ROOT:-$ROOT/.secrets.backup}"
OSS_BUCKET="${SECRETS_OSS_BUCKET:-lengmo-secrets}"
OSS_PREFIX="${SECRETS_OSS_PREFIX:-configs}"
OSS_ENDPOINT="${SECRETS_OSS_ENDPOINT:-oss-cn-beijing.aliyuncs.com}"
OSS_URI="${SECRETS_OSS_URI:-oss://$OSS_BUCKET/$OSS_PREFIX}"
OSS_CONFIG_FILE="${SECRETS_OSS_CONFIG:-$SECRETS_DIR/ossutilconfig}"

usage() {
    cat <<EOF
Usage: $0 <init|push|pull|install>

Commands:
  init     Create .secrets and placeholder files.
  push     Sync .secrets to $OSS_URI.
  pull     Sync $OSS_URI to .secrets.
  install  Install supported files from .secrets to this machine.

Environment:
  SECRETS_DIR          Local secrets directory. Default: $SECRETS_DIR
  SECRETS_OSS_BUCKET   OSS bucket. Default: $OSS_BUCKET
  SECRETS_OSS_PREFIX   OSS prefix. Default: $OSS_PREFIX
  SECRETS_OSS_ENDPOINT OSS endpoint. Default: $OSS_ENDPOINT
  SECRETS_OSS_URI      Full OSS URI override. Default: $OSS_URI
  SECRETS_OSS_CONFIG   ossutil config file. Default: $OSS_CONFIG_FILE
EOF
}

require_ossutil() {
    if ! command -v ossutil >/dev/null 2>&1; then
        echo "错误: 缺少 ossutil" >&2
        exit 1
    fi
}

has_oss_config_credentials() {
    [[ -f "$OSS_CONFIG_FILE" ]] &&
        grep -Eq '^accessKeyId=.+$' "$OSS_CONFIG_FILE" &&
        grep -Eq '^accessKeySecret=.+$' "$OSS_CONFIG_FILE"
}

is_default_opencode_template() {
    local file="$1"

    [[ -f "$file" ]] && [[ "$(tr -d '[:space:]' < "$file")" == "{}" ]]
}

oss_args() {
    local args=(--endpoint "$OSS_ENDPOINT")

    if has_oss_config_credentials; then
        args+=(--config-file "$OSS_CONFIG_FILE")
    fi

    printf '%s\n' "${args[@]}"
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

    if [[ ! -f "$SECRETS_DIR/opencode.json" ]]; then
        printf '{}\n' > "$SECRETS_DIR/opencode.json"
        chmod 600 "$SECRETS_DIR/opencode.json"
        echo "created: $SECRETS_DIR/opencode.json"
    else
        echo "exists: $SECRETS_DIR/opencode.json"
    fi
}

push_secrets() {
    require_ossutil

    if [[ ! -d "$SECRETS_DIR" ]]; then
        echo "错误: $SECRETS_DIR 不存在，请先运行: $0 init" >&2
        exit 1
    fi
    if ! has_oss_config_credentials; then
        echo "错误: $OSS_CONFIG_FILE 未填写 accessKeyId/accessKeySecret，拒绝 push 空 OSS 配置" >&2
        exit 1
    fi

    mapfile -t extra_args < <(oss_args)
    ossutil sync "$SECRETS_DIR" "$OSS_URI" --delete --no-progress --force "${extra_args[@]}"
}

pull_secrets() {
    require_ossutil

    mkdir -p "$SECRETS_DIR" "$BACKUP_ROOT"
    chmod 700 "$SECRETS_DIR" "$BACKUP_ROOT"

    local backup_dir
    backup_dir="$BACKUP_ROOT/$(date +%Y%m%d%H%M%S)"

    mapfile -t extra_args < <(oss_args)
    ossutil sync "$OSS_URI" "$SECRETS_DIR" --delete --backup-dir "$backup_dir" --no-progress --force "${extra_args[@]}"
    chmod 700 "$SECRETS_DIR"
    find "$SECRETS_DIR" -type f -exec chmod 600 {} +
}

install_secret_file() {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]]; then
        echo "skip: $source"
        return
    fi

    mkdir -p "$(dirname "$target")"
    install -m 600 "$source" "$target"
    echo "installed: $target"
}

install_secrets() {
    if [[ ! -d "$SECRETS_DIR" ]]; then
        echo "错误: $SECRETS_DIR 不存在，请先运行: $0 init 或 $0 pull" >&2
        exit 1
    fi

    if is_default_opencode_template "$SECRETS_DIR/opencode.json"; then
        echo "skip: $SECRETS_DIR/opencode.json (template 未填写)"
    else
        install_secret_file "$SECRETS_DIR/opencode.json" "$HOME/.config/opencode/opencode.json"
    fi

    if has_oss_config_credentials; then
        install_secret_file "$SECRETS_DIR/ossutilconfig" "$HOME/.ossutilconfig"
    else
        echo "skip: $SECRETS_DIR/ossutilconfig (accessKeyId/accessKeySecret 未填写)"
    fi
}

command="${1:-}"
case "$command" in
    init)
        init_secrets
        ;;
    push)
        push_secrets
        ;;
    pull)
        pull_secrets
        ;;
    install)
        install_secrets
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
