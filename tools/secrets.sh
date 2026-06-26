#!/usr/bin/env bash
# Manage local .secrets files and sync supported secrets with OSS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$ROOT/.secrets}"
OSS_BUCKET="${SECRETS_OSS_BUCKET:-lengmo-secrets}"
OSS_PREFIX="${SECRETS_OSS_PREFIX:-configs}"
OSS_ENDPOINT="${SECRETS_OSS_ENDPOINT:-oss-cn-beijing.aliyuncs.com}"
OSS_URI="${SECRETS_OSS_URI:-oss://$OSS_BUCKET/$OSS_PREFIX}"
OSS_CONFIG_FILE="${SECRETS_OSS_CONFIG:-$SECRETS_DIR/ossutilconfig}"
OPENCODE_SECRET="opencode.json"
OPENCODE_NAME="opencode"
OPENCODE_TARGET="$HOME/.config/opencode/opencode.json"
CLAUDE_BAILIAN_SECRET="claude.bailian.json"
CLAUDE_BAILIAN_NAME="claude.bailian"
CLAUDE_BAILIAN_TARGET="$HOME/.claude/settings.json"

usage() {
    cat <<EOF
Usage: $0 <init|ls|push|pull|install> [secret-name]

Commands:
  init     Create .secrets/ossutilconfig template.
  ls       List supported secret files.
  push     Upload .secrets/<secret-name> to OSS.
  pull     Download <secret-name> from OSS to .secrets.
  install  Install .secrets/<secret-name> to this machine.

Supported secrets:
  opencode         -> $OPENCODE_TARGET
  claude.bailian   -> $CLAUDE_BAILIAN_TARGET

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

list_secrets() {
    printf '%s\t%s\n' "$OPENCODE_NAME" "$OPENCODE_TARGET"
    printf '%s\t%s\n' "$CLAUDE_BAILIAN_NAME" "$CLAUDE_BAILIAN_TARGET"
}

supported_secret() {
    if [[ $# -ne 1 ]]; then
        usage >&2
        exit 1
    fi

    local name="$1"

    case "$name" in
        "$OPENCODE_NAME")
            printf '%s\n' "$OPENCODE_SECRET"
            ;;
        "$CLAUDE_BAILIAN_NAME")
            printf '%s\n' "$CLAUDE_BAILIAN_SECRET"
            ;;
        *)
            echo "错误: 不支持的 secret: $name" >&2
            echo "支持的 secret:" >&2
            list_secrets >&2
            exit 1
            ;;
    esac
}

install_target_for_secret() {
    case "$1" in
        "$OPENCODE_SECRET") printf '%s\n' "$OPENCODE_TARGET" ;;
        "$CLAUDE_BAILIAN_SECRET") printf '%s\n' "$CLAUDE_BAILIAN_TARGET" ;;
        *) return 1 ;;
    esac
}

oss_args() {
    printf '%s\n' --endpoint "$OSS_ENDPOINT" --config-file "$OSS_CONFIG_FILE"
}

secret_object_uri() {
    local name="$1"

    printf '%s/%s\n' "${OSS_URI%/}" "$name"
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
}

push_secrets() {
    local name source
    name="$(supported_secret "$@")"
    source="$SECRETS_DIR/$name"

    require_ossutil
    require_oss_config_credentials

    if [[ ! -f "$source" ]]; then
        echo "错误: 缺少 $source" >&2
        exit 1
    fi

    mapfile -t extra_args < <(oss_args)
    ossutil cp "$source" "$(secret_object_uri "$name")" --no-progress --force "${extra_args[@]}"
}

pull_secrets() {
    local name target
    name="$(supported_secret "$@")"
    target="$SECRETS_DIR/$name"

    require_ossutil
    require_oss_config_credentials

    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"

    mapfile -t extra_args < <(oss_args)
    ossutil cp "$(secret_object_uri "$name")" "$target" --no-progress --force "${extra_args[@]}"
    chmod 600 "$target"
}

install_secrets() {
    local name source target
    name="$(supported_secret "$@")"
    source="$SECRETS_DIR/$name"
    target="$(install_target_for_secret "$name")"

    if [[ ! -f "$source" ]]; then
        echo "错误: 缺少 $source，请先运行: $0 pull $name" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$target")"
    install -m 600 "$source" "$target"
    echo "installed: $target"
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
        list_secrets
        ;;
    push)
        push_secrets "$@"
        ;;
    pull)
        pull_secrets "$@"
        ;;
    install)
        install_secrets "$@"
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
