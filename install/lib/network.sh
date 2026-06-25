#!/usr/bin/env bash

CONFIGS_CN="${CONFIGS_CN:-0}"
CONFIGS_ARGS=()

configs_apply_cn_network() {
    local git_config_index

    export GITHUB_PROXY="${GITHUB_PROXY:-https://gh-proxy.com/}"
    export PLAYWRIGHT_DOWNLOAD_HOST="${PLAYWRIGHT_DOWNLOAD_HOST:-https://npmmirror.com/mirrors/playwright}"
    export ELECTRON_MIRROR="${ELECTRON_MIRROR:-https://npmmirror.com/mirrors/electron/}"
    export PIP_INDEX_URL="${PIP_INDEX_URL:-https://mirrors.aliyun.com/pypi/simple/}"
    export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-$PIP_INDEX_URL}"
    export UV_INDEX_URL="${UV_INDEX_URL:-$PIP_INDEX_URL}"
    export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://mirrors.aliyun.com/rustup}"
    export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://mirrors.aliyun.com/rustup/rustup}"
    export CARGO_NET_GIT_FETCH_WITH_CLI="${CARGO_NET_GIT_FETCH_WITH_CLI:-true}"
    export CARGO_SOURCE_CRATES_IO_REPLACE_WITH="${CARGO_SOURCE_CRATES_IO_REPLACE_WITH:-ustc}"
    export CARGO_SOURCE_USTC_REGISTRY="${CARGO_SOURCE_USTC_REGISTRY:-https://mirrors.ustc.edu.cn/crates.io-index}"
    export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"

    if [[ "${CONFIGS_GIT_PROXY_APPLIED:-0}" != "1" ]]; then
        git_config_index="${GIT_CONFIG_COUNT:-0}"
        export "GIT_CONFIG_KEY_${git_config_index}=url.${GITHUB_PROXY%/}/https://github.com/.insteadOf"
        export "GIT_CONFIG_VALUE_${git_config_index}=https://github.com/"
        export GIT_CONFIG_COUNT="$((git_config_index + 1))"
        export CONFIGS_GIT_PROXY_APPLIED=1
    fi
}

configs_parse_network_args() {
    CONFIGS_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -cn | --cn)
                CONFIGS_CN=1
                ;;
            *)
                CONFIGS_ARGS+=("$1")
                ;;
        esac
        shift
    done

    export CONFIGS_CN
    if [[ "$CONFIGS_CN" == "1" ]]; then
        configs_apply_cn_network
    fi
}

configs_is_cn() {
    [[ "${CONFIGS_CN:-0}" == "1" ]]
}

configs_github_url() {
    local url="$1"

    if configs_is_cn; then
        case "$url" in
            https://github.com/* | https://api.github.com/* | https://raw.githubusercontent.com/* | https://objects.githubusercontent.com/*)
                printf '%s%s\n' "${GITHUB_PROXY%/}/" "$url"
                return
                ;;
        esac
    fi

    printf '%s\n' "$url"
}

configs_git() {
    if configs_is_cn; then
        git -c "url.${GITHUB_PROXY%/}/https://github.com/.insteadOf=https://github.com/" "$@"
    else
        git "$@"
    fi
}
