#!/bin/sh
set -eu

mkdir -p "$VAULT_PATH" "$XDG_CONFIG_HOME/qmd" "$XDG_CACHE_HOME/qmd"

if ! qmd collection show "$QMD_COLLECTION" >/dev/null 2>&1; then
    qmd collection add "$VAULT_PATH" --name "$QMD_COLLECTION"
fi

qmd update

ob sync --path "$VAULT_PATH" --continuous &
sync_pid=$!

(
    while kill -0 "$sync_pid" 2>/dev/null; do
        sleep "$QMD_UPDATE_INTERVAL"
        qmd update || printf '%s\n' 'qmd update failed; will retry on the next interval' >&2
    done
) &
update_pid=$!

shutdown() {
    kill "$update_pid" "$sync_pid" 2>/dev/null || true
    wait "$update_pid" "$sync_pid" 2>/dev/null || true
}

trap shutdown INT TERM EXIT

qmd mcp --http --host "$QMD_HOST" --port "$QMD_PORT" &
mcp_pid=$!
wait "$mcp_pid"