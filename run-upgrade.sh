#!/usr/bin/env bash

set -euo pipefail

source "conf/common.sh"

init_ledger_environment

_info "Capturing Alice's party ID."
party=$(_get_alice_party_id)

_info "Capturing upgrade package ID."
package_id=$(daml damlc inspect-dar --json ${MODEL_UPGRADE} \
                 | jq -r '.main_package_id')

_info "Party ID: $party
Package ID: $package_id"

mkdir -pv target

_info "Initializing upgraders."
cat <<EOF > target/init.json
{
  "upgradeCoordinator": "$party",
  "upgraders": [
    "$party"
  ]
}
EOF

daml script ${LEDGER_SCRIPT_CONNECTION} \
     --dar ${MODEL_UPGRADE} \
     --script-name "DA.DamlUpgrade.InitiateUpgrade:initializeUpgraders" \
     --input-file target/init.json

docker run ${DOCKER_CONFIG} "${DAML_UPGRADE_IMAGE}" \
    java -jar upgrade-runner.jar init-upgrader \
    --config ${UPGRADE_CONF} \
    --upgrader "$party" \
    --upgrade-package-id "$package_id" \
    ${LEDGER_DOCKER_CONNECTION}

_info "Accepting upgrade proposals."
cat <<EOF > target/parties.json
[
    "$party"
]
EOF

daml script ${LEDGER_SCRIPT_CONNECTION} \
     --dar ${MODEL_UPGRADE} \
     --script-name "DA.DamlUpgrade.UpgradeConsent:acceptUpgradeProposalsScript" \
     --input-file target/parties.json

_info "Running upgrade."

docker run ${DOCKER_CONFIG} "${DAML_UPGRADE_IMAGE}" \
    java -jar upgrade-runner.jar run-upgrade \
    --config ${UPGRADE_CONF} \
    --upgrader "$party" \
    --upgrade-package-id "$package_id" \
    ${LEDGER_DOCKER_CONNECTION}

_info "Cleaning up upgrade state."

docker run ${DOCKER_CONFIG} "${DAML_UPGRADE_IMAGE}" \
    java -jar upgrade-runner.jar cleanup \
    --config ${CLEANUP_CONF} \
    --upgrader "$party" \
    --upgrade-package-id "$package_id" \
    --batch-size 10 \
     ${LEDGER_DOCKER_CONNECTION}

mkdir -p target

echo "\"$party\"" > target/upgrade-coordinator.party

daml script ${LEDGER_SCRIPT_CONNECTION} \
     --dar ${MODEL_UPGRADE} \
     --script-name "DA.DamlUpgrade.Status:cleanupStatus" \
     --input-file target/upgrade-coordinator.party

_info "Upgrade complete."
