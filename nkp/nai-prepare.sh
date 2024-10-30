#!/usr/bin/env bash

set -ex
set -o pipefail

# Installing dependencies on NKP
# Cert-manager and Prometheus are already provided by NKP

ISTIO_VERSION=1.20.8
KNATIVE_VERSION=1.13.1
# KSERVE_VERSION=v0.13.1
KSERVE_VERSION=v0.14.0 # Needed for NIM

## Deploy Istio 1.20.8
helm upgrade --install istio-base base --repo https://istio-release.storage.googleapis.com/charts --version=$ISTIO_VERSION -n istio-system --create-namespace --wait

helm upgrade --install istiod istiod --repo https://istio-release.storage.googleapis.com/charts --version=$ISTIO_VERSION -n istio-system \
    --set gateways.securityContext.runAsUser=0 \
    --set gateways.securityContext.runAsGroup=0 \
    --wait

helm upgrade --install istio-ingressgateway gateway --repo https://istio-release.storage.googleapis.com/charts --version=$ISTIO_VERSION -n istio-system \
    --set securityContext.runAsUser=0 \
    --set securityContext.runAsGroup=0 \
    --set containerSecurityContext.runAsUser=0 \
    --set containerSecurityContext.runAsGroup=0 \
    --wait

## Deploy Knative 1.13.1 
helm upgrade --install knative-serving-crds nai-knative-serving-crds --repo https://nutanix.github.io/helm-releases  --version=$KNATIVE_VERSION -n knative-serving --create-namespace --wait

helm upgrade --install knative-serving nai-knative-serving --repo https://nutanix.github.io/helm-releases -n knative-serving --version=$KNATIVE_VERSION --wait

helm upgrade --install knative-istio-controller nai-knative-istio-controller --repo https://nutanix.github.io/helm-releases -n knative-serving --version=$KNATIVE_VERSION --wait

kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-nodeselector":"enabled"}}'

kubectl patch configmap config-autoscaler -n knative-serving --patch '{"data":{"enable-scale-to-zero":"false"}}'

## Deploy Kserve 0.14.1
helm upgrade --install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version=$KSERVE_VERSION -n kserve --create-namespace --wait

helm upgrade --install kserve oci://ghcr.io/kserve/charts/kserve --version=$KSERVE_VERSION -n kserve --wait \
--set kserve.modelmesh.enabled=false --set kserve.controller.image=docker.io/nutanix/nai-kserve-controller \
--set kserve.controller.tag=$KSERVE_VERSION