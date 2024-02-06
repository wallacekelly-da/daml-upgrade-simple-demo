#!/usr/bin/env bash

set -euo pipefail

source "common.sh"

_info "Building upgrade model"
(cd upgrade-model && daml build)
