#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Create secrets
export IMAGE_PULL_SECRET="registry-image-pull-secret"
kubectl create ns envoy-gateway-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ${IMAGE_PULL_SECRET} \
  --docker-server=$IMAGE_REGISTRY_URL \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n envoy-gateway-system \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create ns kserve --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ${IMAGE_PULL_SECRET}  \
  --docker-server=$IMAGE_REGISTRY_URL \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n kserve \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create ns opentelemetry --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ${IMAGE_PULL_SECRET}  \
  --docker-server=$IMAGE_REGISTRY_URL \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n opentelemetry \
  --dry-run=client -o yaml | kubectl apply -f -

# Download helm charts from registry
helm pull oci://$IMAGE_REGISTRY_URL/gateway-crds-helm --version v1.7.0
helm pull oci://$IMAGE_REGISTRY_URL/gateway-helm --version v1.7.0
helm pull oci://$IMAGE_REGISTRY_URL/kserve-crd --version v0.15.0
helm pull oci://$IMAGE_REGISTRY_URL/kserve --version v0.15.0
helm pull oci://$IMAGE_REGISTRY_URL/nai-core --version 2.7.0
helm pull oci://$IMAGE_REGISTRY_URL/nai-operators --version 2.7.0
helm pull oci://$IMAGE_REGISTRY_URL/opentelemetry-operator --version 0.102.0

export REGISTRY="${IMAGE_REGISTRY_URL}" # to match template
envsubst < templates/eg-config-for-gateway-mode.yaml.template > eg-config-for-gateway-mode.yaml

# Install Envoy Gateway with AI Gateway Mode
helm template eg ./gateway-crds-helm-v1.7.0.tgz --set crds.gatewayAPI.enabled=true --set crds.envoyGateway.enabled=true | kubectl apply --server-side --force-conflicts -f -
helm upgrade --install eg ./gateway-helm-v1.7.0.tgz \
  -n envoy-gateway-system --create-namespace --wait \
  --set global.images.envoyGateway.image=${IMAGE_REGISTRY_URL}/nutanix/nai-gateway:v1.7.0 \
  --set global.images.ratelimit.image=${IMAGE_REGISTRY_URL}/nutanix/nai-ratelimit:99d85510 \
  --set global.imagePullSecrets[0].name=${IMAGE_PULL_SECRET} \
  -f ./eg-config-for-gateway-mode.yaml


# NOTE: Not in 2.7 docs
# Create an Envoy Proxy resource for the Envoy Gateway to pull image from local private registry
# cat <<EOF | kubectl apply -f -
# apiVersion: gateway.envoyproxy.io/v1alpha1
# kind: EnvoyProxy
# metadata:
#   name: nai-envoyproxy
#   namespace: envoy-gateway-system
# spec:
#   provider:
#     type: Kubernetes
#     kubernetes:
#       envoyDeployment:
#         pod:
#           imagePullSecrets:
#             - name: ${IMAGE_PULL_SECRET}
#         container:
#           image: "${IMAGE_REGISTRY_URL}/nutanix/nai-envoy:distroless-v1.37.0"
# EOF

# Install Kserve
helm upgrade --install kserve-crd ./kserve-crd-v0.15.0.tgz -n kserve --create-namespace --wait
helm upgrade --install kserve ./kserve-v0.15.0.tgz \
  -n kserve --wait \
  --set kserve.controller.deploymentMode=RawDeployment \
  --set kserve.controller.gateway.disableIngressCreation=true \
  --set kserve.controller.image=${IMAGE_REGISTRY_URL}/nutanix/nai-kserve-controller \
  --set kserve.controller.rbacProxyImage=${IMAGE_REGISTRY_URL}/nutanix/nai-kube-rbac-proxy:v0.18.0 \
  --set kserve.controller.imagePullSecrets[0].name=${IMAGE_PULL_SECRET}

# Install OpenTelemetry Operator
helm upgrade --install opentelemetry-operator ./opentelemetry-operator-0.102.0.tgz \
  -n opentelemetry --create-namespace --wait \
  --set manager.image.repository=${IMAGE_REGISTRY_URL}/nutanix/nai-opentelemetry-operator \
  --set manager.collectorImage.repository=${IMAGE_REGISTRY_URL}/nutanix/nai-opentelemetry-collector-k8s \
  --set kubeRBACProxy.image.repository=${IMAGE_REGISTRY_URL}/nutanix/nai-kube-rbac-proxy \
  --set imagePullSecrets[0].name=${IMAGE_PULL_SECRET}