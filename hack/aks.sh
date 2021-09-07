#!/bin/bash

set -eux

RGNAME="${RGNAME:-myrg}"
LOCATION="eastus"
CLUSTER_NAME="${RGNAME}k8s"

az group create --location "$LOCATION" --name "$RGNAME"

az aks create -g "$RGNAME" -n "$CLUSTER_NAME" \
  --load-balancer-sku Standard \
  --load-balancer-managed-outbound-ip-count 2 \
  --kubernetes-version 1.20.9 \
  --vm-set-type VirtualMachineScaleSets \
  --nodepool-name workers \
  --node-vm-size Standard_DS2_v2 \
  --enable-cluster-autoscaler \
  --min-count 5 \
  --max-count 30 \
  --node-count 5 \
  --os-sku Ubuntu \
  --outbound-type loadBalancer

az aks get-credentials -g "$RGNAME" --name "$CLUSTER_NAME"
