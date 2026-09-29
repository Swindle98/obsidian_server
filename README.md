# Headless Obsidian Sync + QMD MCP

This image is based on the Linux `node:22-bookworm-slim` server image and installs:

- [Obsidian Headless](https://obsidian.md/help/headless) for Obsidian Sync
- [QMD](https://github.com/tobi/qmd) as an HTTP MCP server

The container continuously syncs `/vault` and periodically updates QMD's index. QMD's MCP endpoint is available at `http://localhost:8181/mcp`.

## First-time setup

Obsidian Headless login is interactive, so authenticate and configure the persistent container state before starting the long-running service:

```sh
docker compose run --rm --entrypoint sh obsidian-qmd
ob login
ob sync-list-remote
ob sync-setup --vault "My Vault" --path /vault
exit
```

The `obsidian-state` volume stores the login and sync configuration. Back up the volume along with the vault. Do not use desktop Sync and Headless Sync for the same device or vault at the same time.

Start the service:

```sh
docker compose up -d --build
```

The first startup creates a QMD collection named `vault`, indexes the Markdown files, and starts the MCP HTTP server. QMD downloads its local models into the persistent `qmd-cache` volume when semantic search is first used.

## Configuration

The image accepts these environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `VAULT_PATH` | `/vault` | Local synced vault path |
| `QMD_COLLECTION` | `vault` | QMD collection name |
| `QMD_HOST` | `0.0.0.0` | MCP bind address |
| `QMD_PORT` | `8181` | MCP HTTP port |
| `QMD_UPDATE_INTERVAL` | `300` | Seconds between QMD index updates |
| `QMD_ALLOWED_HOSTS` | unset | Optional QMD host allowlist |

QMD's HTTP server has no authentication. Keep port 8181 on a trusted network or put an authenticated reverse proxy in front of it.

## Build and smoke test

```sh
docker compose build
docker compose up -d
curl http://localhost:8181/health
```

The image is Linux-only at runtime. Obsidian documents that the Headless native birthtime addon is not included on Linux, so sync proceeds without preserving file creation timestamps.
