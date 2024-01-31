

MODEL_V1=testv1/.daml/dist/test-0.0.1.dar
MODEL_V2=testv2/.daml/dist/test-0.0.2.dar
MODEL_UPGRADE=upgrade-model/.daml/dist/upgrade-test-1.0.0.dar
UPGRADE_PACKAGE_ID=upgrade-model/package_id
ALICE_PARTY_ID=alice_party_id

# .PHONY: build-models
# build-models: ${MODEL_V1} ${MODEL_V2}

# ${MODEL_V1}:
# 	(cd testv1 && daml build)

# ${MODEL_V2}:
# 	(cd testv2 && daml build)

# .PHONY: upgrade-codegen
# upgrade-codegen: upgrade-model/daml.yaml

# upgrade-model/daml.yaml: ${MODEL_V1} ${MODEL_V2}
# 	docker run --platform=linux/amd64 --rm --user 1000:1000 -v .:/work \
# 		digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
# 		upgrade-codegen generate /work/${MODEL_V1} /work/${MODEL_V2}  \
# 		-v 1.0.0 -o /work/upgrade-model

.PHONY: build-upgrade-model
build-upgrade-model: ${UPGRADE_PACKAGE_ID}

${MODEL_UPGRADE}: upgrade-model/daml.yaml
	(cd upgrade-model && daml build)

${UPGRADE_PACKAGE_ID}: ${MODEL_UPGRADE}
	 daml damlc inspect-dar --json ${MODEL_UPGRADE} \
		| jq '.main_package_id' > ${UPGRADE_PACKAGE_ID}

.PHONY: run-ledger
run-ledger: ${MODEL_V1} ${MODEL_V2} ${MODEL_UPGRADE}
	 daml sandbox --debug \
		--dar ${MODEL_V1} \
        --dar ${MODEL_V2} \
        --dar ${MODEL_UPGRADE}

.PHONY: run-script
run-script: ${ALICE_PARTY_ID}

${ALICE_PARTY_ID}: ${MODEL_V1}
	daml script --ledger-host localhost --ledger-port 6865 \
	   --dar ${MODEL_V1} \
	   --script-name Main:test

	daml ledger list-parties --host localhost --port 6865 --json \
       | jq -r 'first(.|map(.party)|.[] | select(contains("alice")))' \
       > ${ALICE_PARTY_ID}

.PHONY: run-navigator
run-navigator:
	daml navigator server --feature-user-management=false


.PHONY: clean
clean:
	(cd testv1 && daml clean)
	(cd testv2 && daml clean)
	rm -rfv upgrade-model
