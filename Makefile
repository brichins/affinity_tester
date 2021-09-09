## define variables

RGNAME ?= myrg
LOCATION := eastus
CLUSTER_NAME := ${RGNAME}k8s

# K8S_VERSION := 1.18.19
K8S_VERSION := 1.19.13
# K8S_VERSION := 1.20.9

## run local client

.PHONY: client
client:
	LB_IP=$$(kubectl get service affinity-tester -o jsonpath='{.status.loadBalancer.ingress[].ip}'); \
	while [ -z $$LB_IP ]; do \
		sleep 10; \
		LB_IP=$$(kubectl get service affinity-tester -o jsonpath='{.status.loadBalancer.ingress[].ip}'); \
	done; \
	docker run --rm -it -u $$UID -v $(PWD)/client:/client --env-file env.list -e TARGET_ADDR=$$LB_IP elixir:1.12.2 \
		bash -c "env | grep TARGET; cd /client && iex -S mix"

## commands to run stuff on k8s

.PHONY: apply-service
apply-service: apply-deployment
	kubectl apply -f kubernetes/service.yaml
	kubectl get service/affinity-tester

.PHONY: apply-deployment
apply-deployment:
	kubectl apply -f kubernetes/deployment.yaml
	kubectl wait deployment/affinity-tester --for condition=available --timeout=120s
	kubectl get deployment/affinity-tester

.PHONY: node-scaleup
node-scaleup:
	kubectl apply -f kubernetes/dummy-deployment.yaml

.PHONY: clean
clean:
	kubectl delete -f kubernetes
	find . -type d -name _build -delete

## build and push to dockerhub.com

.PHONY: build
build:
	docker build -t affinity_tester .

.PHONY: push
push:
	docker login
	docker image tag affinity_tester faddegon/affinity_tester:0.1
	docker push faddegon/affinity_tester:0.1

.PHONY: create-aks
create-aks:
	az group create --location $(LOCATION) --name $(RGNAME)

	az aks create -g $(RGNAME) -n $(CLUSTER_NAME) \
		--load-balancer-sku Standard \
		--load-balancer-managed-outbound-ip-count 2 \
		--kubernetes-version $(K8S_VERSION) \
		--vm-set-type VirtualMachineScaleSets \
		--nodepool-name workers \
		--node-vm-size Standard_DS2_v2 \
		--enable-cluster-autoscaler \
		--min-count 5 \
		--max-count 15 \
		--node-count 5 \
		--os-sku Ubuntu \
		--outbound-type loadBalancer \
		--verbose

	az aks get-credentials -g $(RGNAME) --name $(CLUSTER_NAME)