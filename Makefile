

MODEL_V1=testv1/.daml/dist/test-0.0.1.dar
MODEL_V2=testv2/.daml/dist/test-0.0.2.dar
MODEL_UPGRADE=upgrade-model/.daml/dist/upgrade-test-1.0.0.dar

.PHONY: build-models
build-models: ${MODEL_V1} ${MODEL_V2}

${MODEL_V1}:
	(cd testv1 && daml build)

${MODEL_V2}:
	(cd testv2 && daml build)

.PHONY: upgrade-codegen
upgrade-codegen: upgrade-model/daml.yaml

upgrade-model/daml.yaml: ${MODEL_V1} ${MODEL_V2}
	docker run --platform=linux/amd64 --rm --user 1000:1000 -v .:/work \
		digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
		upgrade-codegen generate /work/${MODEL_V1} /work/${MODEL_V2}  \
		-v 1.0.0 -o /work/upgrade-model

.PHONY: build-upgrade-model
build-upgrade-model: ${MODEL_UPGRADE}

${MODEL_UPGRADE}: upgrade-model/daml.yaml
	(cd upgrade-model && daml build)

.PHONY: run-ledger
run-ledger: ${MODEL_V1} ${MODEL_V2} ${MODEL_UPGRADE}
	 daml sandbox --debug \
		--dar ${MODEL_V1} \
        --dar ${MODEL_V2} \
        --dar ${MODEL_UPGRADE}

.PHONY: run-script
run-script: ${MODEL_V1}
	daml script --ledger-host localhost --ledger-port 6865 \
	   --dar ${MODEL_V1} \
	   --script-name Main:test

.PHONY: run-navigator
run-navigator:
	daml navigator server --feature-user-management=false

.PHONY: clean
clean:
	(cd testv1 && daml clean)
	(cd testv2 && daml clean)
	rm -rfv upgrade-model
