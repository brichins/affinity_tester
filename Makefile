.PHONY: build
build:
	docker build -t affinity_tester .

.PHONY: push
push:
	docker login
	docker image tag affinity_tester faddegon/affinity_tester:0.1
	docker push faddegon/affinity_tester:0.1

