#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

_info "Building upgrade model"
(cd upgrade-model && daml build) && cp ${MODEL_UPGRADE} target
