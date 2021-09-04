## run local client

.PHONY: client
client:
	docker run --rm -it -v $(PWD)/client:/client --env-file env.list elixir:1.12.2 bash -c "env | grep TARGET; cd /client && iex -S mix"

## commands to run stuff on k8s

.PHONY: apply-service
apply-service:
	kubectl apply -f kubernetes/service.yaml
	kubectl get service/affinity-tester

.PHONY: apply-deployment
apply-deployment:
	kubectl apply -f kubernetes/deployment.yaml
	kubectl get deployment/affinity-tester

.PHONY: node-scaleup
node-scaleup:
	kubectl apply -f kubernetes/dummy-deployment.yaml

.PHONY: clean
clean:
	kubectl delete -f kubernetes

## build and push to dockerhub.com

.PHONY: build
build:
	docker build -t affinity_tester .

.PHONY: push
push:
	docker login
	docker image tag affinity_tester faddegon/affinity_tester:0.1
	docker push faddegon/affinity_tester:0.1
