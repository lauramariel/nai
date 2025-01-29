#!/usr/bin/env bash
set -ex

NAI_UI_ENDPOINT="$1"

# Patch catalog item in NKP with the endpoint URL
kubectl patch cm nai-ui -n ${NKP_NAMESPACE} -p '{"data":{"dashboardLink":"'${NAI_UI_ENDPOINT}'"}}'

# Patch configmaps NCN-104322
kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-nodeselector":"enabled"},"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}}}'
kubectl patch configmap config-autoscaler -n knative-serving --patch '{"data":{"enable-scale-to-zero":"false"},"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}}}'