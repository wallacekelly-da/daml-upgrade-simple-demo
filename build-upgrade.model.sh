#!/usr/bin/env bash

set -euo pipefail

source "common.sh"

(cd upgrade-model && daml build)
