#!/usr/bin/env bash

set -ex
set -o pipefail

## Deploy Istio 1.20.8
helm upgrade --install istio-base base --repo https://istio-release.storage.googleapis.com/charts --version=1.20.8 -n istio-system --create-namespace --wait

helm upgrade --install istiod istiod --repo https://istio-release.storage.googleapis.com/charts --version=1.20.8 -n istio-system \
    --set gateways.securityContext.runAsUser=0 \
    --set gateways.securityContext.runAsGroup=0 \
    --wait

helm upgrade --install istio-ingressgateway gateway --repo https://istio-release.storage.googleapis.com/charts --version=1.20.8 -n istio-system \
    --set securityContext.runAsUser=0 \
    --set securityContext.runAsGroup=0 \
    --set containerSecurityContext.runAsUser=0 \
    --set containerSecurityContext.runAsGroup=0 \
    --wait

## Deploy Knative 1.13.1 
helm upgrade --install knative-serving-crds nai-knative-serving-crds --repo https://nutanix.github.io/helm-releases  --version=1.13.1 -n knative-serving --create-namespace --wait

helm upgrade --install knative-serving nai-knative-serving --repo https://nutanix.github.io/helm-releases -n knative-serving --version=1.13.1 --wait

helm upgrade --install knative-istio-controller nai-knative-istio-controller --repo https://nutanix.github.io/helm-releases -n knative-serving --version=1.13.1 --wait

kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-nodeselector":"enabled"}}'

kubectl patch configmap config-autoscaler -n knative-serving --patch '{"data":{"enable-scale-to-zero":"false"}}'

## Deploy Kserve 0.13.1
helm upgrade --install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version=v0.13.1 -n kserve --create-namespace --wait

helm upgrade --install kserve oci://ghcr.io/kserve/charts/kserve --version=v0.13.1 -n kserve --wait \
--set kserve.modelmesh.enabled=false --set kserve.controller.image=docker.io/nutanix/nai-kserve-controller \
--set kserve.controller.tag=v0.13.1