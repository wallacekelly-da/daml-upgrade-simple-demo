#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

(cd testv1 && daml clean)
(cd testv2 && daml clean)
rm -rfv upgrade-model target
