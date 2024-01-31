#!/usr/bin/env bash

set -euo pipefail

source "common.sh"


echo "Capturing party ID for Alice."
party=$(daml ledger list-parties --host localhost --port 6865 --json \
            | jq -r 'first(.|map(.party)|.[] | select(contains("alice")))')

echo "Party ID: $party"

echo "Capturing upgrade package ID."

package_id=$(daml damlc inspect-dar --json ${MODEL_UPGRADE} \
                 | jq -r '.main_package_id')

echo "Package ID: $package_id"

cat <<EOF > init.json
{
  "upgradeCoordinator": "$party",
  "upgraders": [
    "$party"
  ]
}
EOF

daml script --ledger-host localhost --ledger-port 6865 \
     --dar ${MODEL_UPGRADE} \
     --script-name "DA.DamlUpgrade.InitiateUpgrade:initializeUpgraders" \
     --input-file init.json

docker run --platform=linux/amd64 --rm --network=host -v .:/work \
    digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
    init-upgrader \
    --config /work/upgrade.conf \
    --upgrader "$party" \
    --upgrade-package-id "$package_id"

cat <<EOF > parties.json
[
    "$party"
]
EOF

daml script --ledger-host localhost --ledger-port 6865 \
     --dar ${MODEL_UPGRADE} \
     --script-name "DA.DamlUpgrade.UpgradeConsent:acceptUpgradeProposalsScript" \
     --input-file parties.json


docker run --platform=linux/amd64 --rm --network=host -v .:/work \
    digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
    run-upgrade \
    --config /work/upgrade.conf \
    --upgrader "$party" \
    --upgrade-package-id "$package_id"


docker run --platform=linux/amd64 --rm --network=host -v .:/work \
    digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
    cleanup \
    --config /work/cleanup.conf \
    --upgrader "$party" \
    --upgrade-package-id "$package_id" \
    --batch-size 10

echo "\"$party\"" > upgrade-coordinator.party

daml script --ledger-host localhost --ledger-port 6865 \
     --dar ${MODEL_UPGRADE} \
     --script-name "DA.DamlUpgrade.Status:cleanupStatus" \
     --input-file upgrade-coordinator.party


