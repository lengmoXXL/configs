#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "用法: $0 <wiki 路径>" >&2
    exit 1
fi

for command in docker realpath; do
    if ! command -v "$command" &>/dev/null; then
        echo "错误: 缺少依赖 $command" >&2
        exit 1
    fi
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
wiki_path=$(realpath "$1")

if [[ ! -d "$wiki_path/.git" ]]; then
    echo "错误: wiki 路径不是 Git 仓库: $wiki_path" >&2
    exit 1
fi
if [[ ! -d "$HOME/.hermes" ]]; then
    echo "错误: Hermes 数据目录不存在: $HOME/.hermes" >&2
    exit 1
fi
if [[ ! -d "$HOME/.ssh" ]]; then
    echo "错误: SSH 配置目录不存在: $HOME/.ssh" >&2
    exit 1
fi
if [[ $(docker info --format '{{.Host.Security.Rootless}}' 2>/dev/null) != true ]]; then
    echo "错误: 此部署要求 rootless Podman，以便容器 root 安全映射到当前用户" >&2
    exit 1
fi

image="wiki-hermes-agent:v2026.7.1"
container="hermes-agent"

echo "构建 $image ..."
docker build \
    --file "$script_dir/Dockerfile" \
    --network host \
    --build-arg HERMES_VERSION=v2026.7.1 \
    --tag "$image" \
    "$script_dir"

if docker inspect "$container" &>/dev/null; then
    echo "替换已有容器 $container ..."
    docker rm --force --volumes "$container" >/dev/null
fi

echo "启动容器 $container ..."
docker run --detach \
    --name "$container" \
    --network host \
    --env HERMES_GATEWAY_BOOTSTRAP_STATE=running \
    --env HERMES_ALLOW_ROOT_GATEWAY=1 \
    --volume "$HOME/.hermes:/opt/data:rw" \
    --volume "$HOME/.ssh:/opt/data/.ssh:ro" \
    --volume "$wiki_path:/workspace/wiki:rw" \
    "$image" >/dev/null

for _ in {1..30}; do
    if [[ $(docker inspect --format '{{.State.Running}}' "$container" 2>/dev/null) == true ]] && \
        docker exec "$container" pgrep --full '/opt/hermes/.venv/bin/hermes gateway run' >/dev/null 2>&1; then
        sleep 2
        if docker exec "$container" pgrep --full '/opt/hermes/.venv/bin/hermes gateway run' >/dev/null 2>&1; then
            echo "迁移完成: Hermes gateway 正在容器 $container 中运行"
            exit 0
        fi
    fi
    sleep 2
done

echo "错误: Hermes 容器在 60 秒内未进入运行状态" >&2
docker logs "$container" >&2 || true
exit 1
