#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env
source ~/.secrets

export REGISTRY_EMAIL="tme@nutanix.com"

# Create secrets
kubectl create ns envoy-gateway-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry registry-image-pull-secret \
  --docker-server=$NAI_IMAGE_REGISTRY \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n envoy-gateway-system

kubectl create ns kserve --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry registry-image-pull-secret \
  --docker-server=$NAI_IMAGE_REGISTRY \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n kserve

kubectl create ns opentelemetry --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry registry-image-pull-secret \
  --docker-server=$NAI_IMAGE_REGISTRY \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n opentelemetry

# Download helm charts from registry
helm pull oci://$NAI_IMAGE_REGISTRY/gateway-crds-helm --version v1.5.0
helm pull oci://$NAI_IMAGE_REGISTRY/gateway-helm --version v1.5.0
helm pull oci://$NAI_IMAGE_REGISTRY/kserve-crd --version v0.15.0
helm pull oci://$NAI_IMAGE_REGISTRY/kserve --version v0.15.0
helm pull oci://$NAI_IMAGE_REGISTRY/nai-core --version 2.5.0
helm pull oci://$NAI_IMAGE_REGISTRY/nai-operators --version 2.5.0
helm pull oci://$NAI_IMAGE_REGISTRY/opentelemetry-operator --version 0.93.0

# Install Envoy Gateway
helm template eg ./gateway-crds-helm-v1.5.0.tgz --set crds.gatewayAPI.enabled=true --set crds.envoyGateway.enabled=true | kubectl apply --server-side --force-conflicts -f -
helm upgrade --install eg ./gateway-helm-v1.5.0.tgz \
    -n envoy-gateway-system --create-namespace --wait \
    --set global.images.envoyGateway.image=$NAI_IMAGE_REGISTRY/nutanix/nai-gateway:v1.5.0 \
    --set global.images.ratelimit.image=$NAI_IMAGE_REGISTRY/nutanix/nai-ratelimit:3e085e5b \
    --set global.imagePullSecrets[0].name=registry-image-pull-secret

# Create an Envoy Proxy resource for the Envoy Gateway to pull image from local private registry
cat <<EOF | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: nai-envoyproxy
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyDeployment:
        pod:
          imagePullSecrets:
            - name: registry-image-pull-secret
        container:
          image: "$NAI_IMAGE_REGISTRY/nutanix/nai-envoy:distroless-v1.35.0"
EOF

# Install Kserve
helm upgrade --install kserve-crd ./kserve-crd-v0.15.0.tgz -n kserve --create-namespace --wait
helm upgrade --install kserve ./kserve-v0.15.0.tgz \
  -n kserve --wait \
  --set kserve.controller.deploymentMode=RawDeployment \
  --set kserve.controller.gateway.disableIngressCreation=true \
  --set kserve.controller.image=$NAI_IMAGE_REGISTRY/nutanix/nai-kserve-controller \
  --set kserve.controller.rbacProxyImage=$NAI_IMAGE_REGISTRY/nutanix/nai-kube-rbac-proxy:v0.18.0 \
  --set kserve.controller.imagePullSecrets[0].name=registry-image-pull-secret

# Install OpenTelemetry Operator
helm upgrade --install opentelemetry-operator ./opentelemetry-operator-0.93.0.tgz \
  -n opentelemetry --create-namespace --wait \
  --set manager.image.repository=$NAI_IMAGE_REGISTRY/nutanix/nai-opentelemetry-operator \
  --set manager.collectorImage.repository=$NAI_IMAGE_REGISTRY/nutanix/nai-opentelemetry-collector-k8s \
  --set kubeRBACProxy.image.repository=$NAI_IMAGE_REGISTRY/nutanix/nai-kube-rbac-proxy \
  --set imagePullSecrets[0].name=registry-image-pull-secret