#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

pid_file="target/canton.pid"
if [ -f "$pid_file" ]; then
    pid=$(<"$pid_file")

    if ps -p $pid > /dev/null; then
        _info "Killing ledger running. (PID: $pid)"
        kill "$pid"
        rm "$pid_file"
    else
        _warning "Stale PID file found, but process not running. Cleaning up $pid_file."
        rm "$pid_file"
        exit 1
    fi
else
    _warning "$pid_file not found, ledger assumed not running."
    exit 1
fi
