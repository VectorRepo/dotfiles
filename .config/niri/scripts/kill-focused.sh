#!/usr/bin/env bash

# Get the PID of the focused window
pid=$(niri msg --json focused-window | jq -r '.pid')

if [[ -z "$pid" || "$pid" == "null" ]]; then
    exit 1
fi

# Kill the entire process group
kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null
