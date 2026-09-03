#!/bin/bash
# 安装 clash-for-linux-install 到 ~/.local/share/clash-for-linux-install

set -e

REPO_URL="https://github.com/nelvko/clash-for-linux-install.git"
GITHUB_PROXY_PREFIX="https://gh-proxy.com/"
BRANCH="master"
SHARE_DIR="${HOME}/.local/share"
INSTALL_DIR="${SHARE_DIR}/clash-for-linux-install"

usage() {
    cat << EOF
用法: $0

环境变量:
  CN=1     通过国内代理 clone GitHub 仓库
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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

if [[ "${CN:-}" == "1" ]]; then
    REPO_URL="${GITHUB_PROXY_PREFIX}${REPO_URL}"
fi

mkdir -p "$SHARE_DIR"

if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "仓库已存在，更新到最新 ${BRANCH}: $INSTALL_DIR"
    git -C "$INSTALL_DIR" remote set-url origin "$REPO_URL"
    git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH"
    git -C "$INSTALL_DIR" checkout "$BRANCH"
    git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH"
elif [[ -e "$INSTALL_DIR" ]]; then
    echo "错误: 目标路径已存在但不是 git 仓库: $INSTALL_DIR"
    exit 1
else
    echo "克隆仓库到: $INSTALL_DIR"
    git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

echo "执行安装脚本..."
cd "$INSTALL_DIR"
bash install.sh

# 在 .bashrc 中关闭 noclobber（oh-my-bash 默认开启会导致文件覆盖报错）
BASHRC="${HOME}/.bashrc"
start_flag="# noclobber-off START"
end_flag="# noclobber-off END"

if ! grep -q "$start_flag" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<EOF

$start_flag
# 关闭 noclobber，允许 > 覆盖已存在文件
set +o noclobber
$end_flag
EOF
    echo "已添加 noclobber 关闭配置到 .bashrc"
fi
