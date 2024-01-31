#!/usr/bin/env bash

set -euo pipefail

source "common.sh"

if [ ! -f ${MODEL_V1} ]; then
    echo "DAR file ${MODEL_V1} not found, run build-base-models-and-codegen.sh."
    exit 1
fi

if [ ! -f ${MODEL_V2} ]; then
    echo "DAR file ${MODEL_V2} not found, run build-base-models-and-codegen.sh."
    exit 1
fi

if [ ! -f ${MODEL_UPGRADE} ]; then
    echo "DAR file ${MODEL_V2} not found, run build-upgrade-model.sh."
    exit 1
fi


pid_file="canton.pid"
if [ -f "$pid_file" ]; then
    pid=$(<"$pid_file")

    if ps -p $pid > /dev/null; then
        echo "INFO: Ledger already running. (PID: $pid)"
        exit 1
    else
        echo "WARNING: Stale PID file found, but process not running. Cleaning up $pid_file and starting ledger."
        rm "$pid_file"
    fi
fi

mkdir -pv log

daml sandbox --debug \
     --dar ${MODEL_V1} \
     --dar ${MODEL_V2} \
     --dar ${MODEL_UPGRADE} \
     &> log/canton-console.log &
echo $! > "$pid_file"

pid=$(<"$pid_file")

echo "Started Canton ledger (PID: $pid) with log output in log/."

echo "Waiting for ledger startup and then initializing ledger."
sleep 10

echo "Running startup script..."
daml script --ledger-host localhost --ledger-port 6865 \
   --dar ${MODEL_V1} \
   --script-name Main:test

echo "Done."
