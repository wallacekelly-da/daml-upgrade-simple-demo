#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

if [ ! -f ${ALICE_JWT_FILE} ]; then
    _error "JWT file ${ALICE_JWT_FILE} missing, download from UI."
fi

jwt_decode $(<${ALICE_JWT_FILE}) | jq '.party' > target/alice.json

init_ledger_environment

_info "Running startup script to initialize ledger."
daml script ${LEDGER_SCRIPT_CONNECTION} \
   --dar ${MODEL_V1} \
   --script-name Main:createTestContracts \
   --input-file target/alice.json

_info "Ledger running and initialized.

Run contract upgrade with ./run-upgrade.sh"
