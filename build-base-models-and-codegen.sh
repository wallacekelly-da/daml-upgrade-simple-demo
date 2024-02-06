#!/usr/bin/env bash

set -euo pipefail

source "common.sh"

_info "Building testv1 model."
(cd testv1 && daml build)

_info "Building testv2 model."
(cd testv2 && daml build)

_info "Generating code for migration."
docker run --platform=linux/amd64 --rm --user 1000:1000 -v .:/work \
    digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
    upgrade-codegen generate /work/${MODEL_V1} /work/${MODEL_V2}  \
    -v 1.0.0 -o /work/upgrade-model


_info "Code generation successful.

At this point, the code in ./upgrade-model needs to be modified to
provide conversion functions and default values. After this is done,
the build can be continued with ./build-upgrade-model.sh."
