FROM node:22-bookworm-slim

ARG OBSIDIAN_HEADLESS_VERSION=0.0.14
ARG QMD_VERSION=2.8.3

ENV NODE_ENV=production \
    HOME=/data/home \
    XDG_CONFIG_HOME=/data/config \
    XDG_CACHE_HOME=/data/cache \
    VAULT_PATH=/vault \
    QMD_COLLECTION=vault \
    QMD_HOST=0.0.0.0 \
    QMD_PORT=8181 \
    QMD_UPDATE_INTERVAL=300

RUN apt-get update \
    && apt-get install --yes --no-install-recommends python3 make g++ \
    && npm install --global --no-fund --no-audit \
        "obsidian-headless@${OBSIDIAN_HEADLESS_VERSION}" \
        "@tobilu/qmd@${QMD_VERSION}" \
    && npm cache clean --force \
    && mkdir -p /data/home /data/config /data/cache /vault \
    && chown -R node:node /data /vault \
    && apt-get purge --yes --auto-remove python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint

USER node
WORKDIR /vault
EXPOSE 8181

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:' + process.env.QMD_PORT + '/health').then(r => { if (!r.ok) process.exit(1) }).catch(() => process.exit(1))"

ENTRYPOINT ["docker-entrypoint"]