#!/usr/bin/env bash

set -euo pipefail

source "common.sh"

(cd testv1 && daml build)
(cd testv2 && daml build)

docker run --platform=linux/amd64 --rm --user 1000:1000 -v .:/work \
    digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
    upgrade-codegen generate /work/${MODEL_V1} /work/${MODEL_V2}  \
    -v 1.0.0 -o /work/upgrade-model
