#!/bin/bash
# Build perf_to_profile from a fixed source commit and optionally publish it to OSS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="42b687e95926099f791847789cc52925ef385ddb"
SOURCE_SHA256="12b3f3026d6181e9e6f10a97611d22a03f39d15de86fd099a48dbb965e47370b"
BAZEL_VERSION="7.4.1"
OUTPUT_DIR="${PERF_TO_PROFILE_OUTPUT_DIR:-${ROOT}/dist}"
OSS_BUCKET="${PERF_TO_PROFILE_OSS_BUCKET:-lengmo-asserts}"
OSS_PREFIX="${PERF_TO_PROFILE_OSS_PREFIX:-tools/perf_to_profile/${SOURCE_COMMIT}}"
OSS_ENDPOINT="${PERF_TO_PROFILE_OSS_ENDPOINT:-}"
PUBLIC_BASE_URL="${PERF_TO_PROFILE_PUBLIC_BASE_URL:-https://${OSS_BUCKET}.oss-cn-beijing.aliyuncs.com}"
PUSH=false

usage() {
    cat << EOF
用法: $0 [--push]

选项:
  --push    构建成功后将二进制和 SHA256 文件上传到 OSS

环境变量:
  PERF_TO_PROFILE_OUTPUT_DIR       构建产物目录，默认 ${OUTPUT_DIR}
  PERF_TO_PROFILE_OSS_BUCKET       OSS bucket，默认 ${OSS_BUCKET}
  PERF_TO_PROFILE_OSS_PREFIX       OSS 对象前缀，默认 ${OSS_PREFIX}
  PERF_TO_PROFILE_OSS_ENDPOINT     可选的 ossutil endpoint
  PERF_TO_PROFILE_PUBLIC_BASE_URL  公网下载根地址
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --push)
            PUSH=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "错误: perf_to_profile 仅支持 Linux"
    exit 1
fi

for dep in curl install mktemp sha256sum tar uname; do
    if ! command -v "$dep" &>/dev/null; then
        echo "错误: 缺少依赖 $dep"
        exit 1
    fi
done

if [[ "$PUSH" == "true" ]] && ! command -v ossutil &>/dev/null; then
    echo "错误: --push 需要 ossutil"
    echo "请先运行: ${ROOT}/install/install-ossutil.sh"
    exit 1
fi

if ! command -v g++ &>/dev/null || [[ ! -f /usr/include/libelf.h || ! -f /usr/include/sys/capability.h ]]; then
    sudo_cmd=()
    if [[ "$(id -u)" -ne 0 ]]; then
        if ! command -v sudo &>/dev/null; then
            echo "错误: 安装编译依赖需要 root 权限或 sudo"
            exit 1
        fi
        sudo_cmd=(sudo)
    fi

    echo "安装 perf_to_profile 编译依赖..."
    if command -v apt-get &>/dev/null; then
        "${sudo_cmd[@]}" apt-get update
        "${sudo_cmd[@]}" apt-get install -y g++ libelf-dev libcap-dev
    elif command -v dnf &>/dev/null; then
        "${sudo_cmd[@]}" dnf install -y gcc-c++ elfutils-libelf-devel libcap-devel
    elif command -v yum &>/dev/null; then
        "${sudo_cmd[@]}" yum install -y gcc-c++ elfutils-libelf-devel libcap-devel
    elif command -v pacman &>/dev/null; then
        "${sudo_cmd[@]}" pacman -Sy --noconfirm gcc libelf libcap
    elif command -v apk &>/dev/null; then
        "${sudo_cmd[@]}" apk add g++ libelf-dev libcap-dev
    elif command -v zypper &>/dev/null; then
        "${sudo_cmd[@]}" zypper install -y gcc-c++ libelf-devel libcap-devel
    else
        echo "错误: 未找到支持的包管理器，无法安装 g++、libelf 和 libcap 开发包"
        exit 1
    fi
fi

if ! command -v g++ &>/dev/null || [[ ! -f /usr/include/libelf.h || ! -f /usr/include/sys/capability.h ]]; then
    echo "错误: perf_to_profile 编译依赖安装不完整"
    exit 1
fi

case "$(uname -m)" in
    x86_64)
        asset="perf_to_profile-linux-amd64"
        bazel_arch="x86_64"
        bazel_sha256="c97f02133adce63f0c28678ac1f21d65fa8255c80429b588aeeba8a1fac6202b"
        ;;
    aarch64 | arm64)
        asset="perf_to_profile-linux-arm64"
        bazel_arch="arm64"
        bazel_sha256="d7aedc8565ed47b6231badb80b09f034e389c5f2b1c2ac2c55406f7c661d8b88"
        ;;
    *)
        echo "错误: 不支持的架构 $(uname -m)"
        exit 1
        ;;
esac

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

source_archive="${tmp_dir}/perf_data_converter.tar.gz"
bazel="${tmp_dir}/bazel"
source_url="https://github.com/google/perf_data_converter/archive/${SOURCE_COMMIT}.tar.gz"
bazel_url="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-${bazel_arch}"

echo "下载 perf_data_converter ${SOURCE_COMMIT:0:12}..."
curl -fL --retry 3 "$source_url" -o "$source_archive"
echo "${SOURCE_SHA256}  ${source_archive}" | sha256sum -c -

echo "下载 Bazel ${BAZEL_VERSION}..."
curl -fL --retry 3 "$bazel_url" -o "$bazel"
echo "${bazel_sha256}  ${bazel}" | sha256sum -c -
chmod +x "$bazel"

tar -xzf "$source_archive" -C "$tmp_dir"
source_dir="${tmp_dir}/perf_data_converter-${SOURCE_COMMIT}"

echo "编译 perf_to_profile..."
(
    cd "$source_dir"
    "$bazel" --batch --output_user_root="${tmp_dir}/bazel-root" \
        build --compilation_mode=opt --strip=always --noshow_progress //src:perf_to_profile
)

mkdir -p "$OUTPUT_DIR"
install -m 755 "${source_dir}/bazel-bin/src/perf_to_profile" "${OUTPUT_DIR}/${asset}"
(
    cd "$OUTPUT_DIR"
    sha256sum "$asset" > "${asset}.sha256"
)

echo ""
echo "构建完成"
echo "  binary: ${OUTPUT_DIR}/${asset}"
echo "  checksum: ${OUTPUT_DIR}/${asset}.sha256"

if [[ "$PUSH" == "true" ]]; then
    destination="oss://${OSS_BUCKET}/${OSS_PREFIX%/}/${asset}"
    checksum_destination="${destination}.sha256"
    binary_args=(
        cp "${OUTPUT_DIR}/${asset}" "$destination" --force
        --content-type application/octet-stream
        --cache-control "public, max-age=31536000, immutable"
    )
    checksum_args=(
        cp "${OUTPUT_DIR}/${asset}.sha256" "$checksum_destination" --force
        --content-type "text/plain; charset=utf-8"
        --cache-control "public, max-age=31536000, immutable"
    )
    if [[ -n "$OSS_ENDPOINT" ]]; then
        binary_args+=(--endpoint "$OSS_ENDPOINT")
        checksum_args+=(--endpoint "$OSS_ENDPOINT")
    fi
    if [[ "${DRY_RUN:-}" == "1" ]]; then
        binary_args+=(--dry-run)
        checksum_args+=(--dry-run)
    fi

    ossutil "${binary_args[@]}"
    ossutil "${checksum_args[@]}"

    public_url="${PUBLIC_BASE_URL%/}/${OSS_PREFIX%/}/${asset}"
    if [[ "${DRY_RUN:-}" == "1" ]]; then
        echo "OSS dry run 完成: $destination"
    else
        echo "已发布: $destination"
        echo "下载地址: $public_url"
    fi
fi
