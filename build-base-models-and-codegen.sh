#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

mkdir -pv target

_info "Building testv1 model."
(cd testv1 && daml build) && cp ${MODEL_V1} target

_info "Building testv2 model."
(cd testv2 && daml build) && cp ${MODEL_V2} target

_info "Generating code for migration."
docker run --platform=linux/amd64 --rm --user 1000:1000 -v .:/work \
    "${DAML_UPGRADE_IMAGE}" \
    upgrade-codegen generate --old /work/${MODEL_V1} --new /work/${MODEL_V2}  \
    -v 1.0.0 -o /work/upgrade-model


_info "Code generation successful.

At this point, the code in ./upgrade-model needs to be modified to
provide conversion functions and default values. After this is done,
the build can be continued with ./build-upgrade-model.sh."
