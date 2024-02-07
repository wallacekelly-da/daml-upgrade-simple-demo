#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

if [ ! -f ${MODEL_V1} ]; then
    _error "DAR file ${MODEL_V1} not found, run build-base-models-and-codegen.sh."
fi

if [ ! -f ${MODEL_V2} ]; then
    _error "DAR file ${MODEL_V2} not found, run build-base-models-and-codegen.sh."
fi

if [ ! -f ${MODEL_UPGRADE} ]; then
    _error "DAR file ${MODEL_UPGRADE} not found, run build-upgrade-model.sh."
fi


pid_file="canton.pid"
if [ -f "$pid_file" ]; then
    pid=$(<"$pid_file")

    if ps -p $pid > /dev/null; then
        _info "Ledger already running. (PID: $pid)"
        exit 1
    else
        _warning "Stale PID file found, but process not running. Cleaning up $pid_file and starting ledger."
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

_info "Started Canton ledger (PID: $pid) with log output in log/

Waiting a few seconds for ledger startup..."

sleep 10

_info "Running startup script to initialize ledger."
daml script --ledger-host localhost --ledger-port 6865 \
   --dar ${MODEL_V1} \
   --script-name Main:test

_info "Ledger running and initialized.

Run contract upgrade with ./run-upgrade.sh

Stop the ledger with ./stop-ledger.sh"
