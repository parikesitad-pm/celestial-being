#!/usr/bin/env bash
# Locks the session with the animated Quickshell lock. A lock that fails to start must never
# leave the session open, so anything short of a confirmed lock falls back to hyprlock.
config="${LOCK_CONFIG:-dap-lock}"

pgrep -x hyprlock >/dev/null && exit 0

qs -c "$config" -n >/dev/null 2>&1 &
pid=$!

for _ in $(seq 1 30); do
    if [ "$(qs -c "$config" ipc call lock secure 2>/dev/null)" = "true" ]; then
        wait "$pid"
        exit 0
    fi
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
done

kill "$pid" 2>/dev/null
exec hyprlock
