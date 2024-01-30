
.PHONY: upgrade
upgrade: models
	docker run --platform=linux/amd64 --rm --user 1000:1000 \
		-v .:/work \
		digitalasset-docker.jfrog.io/daml-upgrade:1.4.2 \
		upgrade-codegen generate /work/testv1/.daml/dist/test-0.0.1.dar \
								 /work/testv2/.daml/dist/test-0.0.2.dar \
		-v 1.0.0 -o /work/upgrade-model

.PHONY: models
models: testv1/.daml/dist/test-0.0.1.dar testv2/.daml/dist/test-0.0.2.dar

testv1/.daml/dist/test-0.0.1.dar: testv1/daml.yaml
	(cd testv1 && daml build)

testv2/.daml/dist/test-0.0.2.dar: testv2/daml.yaml
	(cd testv2 && daml build)

.PHONY: clean
clean:
	(cd testv1 && daml clean)
	(cd testv2 && daml clean)
	rm -rfv upgrade-model
