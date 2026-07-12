ARG HERMES_VERSION=v2026.7.1
FROM docker.io/nousresearch/hermes-agent:${HERMES_VERSION}

# The upstream image leaves platform-specific integrations out of its sealed
# environment. This deployment uses Feishu, so install the exact v2026.7.1
# extra dependencies at build time instead of attempting a runtime install.
RUN uv pip install \
    --python /opt/hermes/.venv/bin/python \
    lark-oapi==1.5.3 \
    qrcode==7.4.2

# deploy.sh runs with rootless Podman, whose container root maps to the current
# host user. Keep Hermes on that mapped identity instead of dropping to the
# image's UID/GID 10000, so bind-mounted Git repositories remain writable.
RUN groupmod --non-unique --gid 0 hermes && \
    usermod --non-unique --uid 0 --gid 0 hermes

WORKDIR /workspace/wiki

# /init from the Hermes image supervises the gateway and handles signals.
CMD ["gateway", "run"]
