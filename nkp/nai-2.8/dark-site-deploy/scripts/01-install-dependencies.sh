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

kubectl create ns lws-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ${IMAGE_PULL_SECRET}  \
  --docker-server=$IMAGE_REGISTRY_URL \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n lws-system \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create ns nai-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret docker-registry ${IMAGE_PULL_SECRET}  \
  --docker-server=$IMAGE_REGISTRY_URL \
  --docker-username=$REGISTRY_USERNAME \
  --docker-password=$REGISTRY_PASSWORD \
  --docker-email=$REGISTRY_EMAIL \
  -n nai-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Download helm charts from registry
helm pull oci://$IMAGE_REGISTRY_URL/gateway-crds-helm --version v1.8.1
helm pull oci://$IMAGE_REGISTRY_URL/gateway-helm --version v1.8.1
helm pull oci://$IMAGE_REGISTRY_URL/kserve-crd --version v0.19.0
helm pull oci://$IMAGE_REGISTRY_URL/kserve-llmisvc-crd --version v0.19.0
helm pull oci://$IMAGE_REGISTRY_URL/kserve-llmisvc-resources --version v0.19.0
helm pull oci://$IMAGE_REGISTRY_URL/kserve-resources --version v0.19.0
helm pull oci://$IMAGE_REGISTRY_URL/nai-core --version 2.8.0
helm pull oci://$IMAGE_REGISTRY_URL/nai-operators --version 2.8.0
helm pull oci://$IMAGE_REGISTRY_URL/opentelemetry-operator --version 0.114.1

export REGISTRY="${IMAGE_REGISTRY_URL}" # to match template
envsubst < templates/eg-config-for-gateway-mode.yaml.template > eg-config-for-gateway-mode.yaml

# Install Envoy Gateway CRDs
helm template eg ./gateway-crds-helm-v1.8.1.tgz \
  --set crds.gatewayAPI.enabled=true \
  --set crds.envoyGateway.enabled=true \
  | kubectl apply --server-side --force-conflicts -f -
  
# Install Envoy Gateway with AI Gateway Mode
helm upgrade --install eg ./gateway-helm-v1.8.1.tgz \
  -n envoy-gateway-system --create-namespace --wait \
  --set global.images.envoyGateway.image=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-gateway:v1.8.1 \
  --set global.images.ratelimit.image=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-ratelimit:1e50889b \
  --set "global.imagePullSecrets[0].name=${IMAGE_PULL_SECRET}" \
  -f ./eg-config-for-gateway-mode.yaml

# Install Kserve CRDs
helm upgrade --install kserve-crd ./kserve-crd-v0.19.0.tgz -n kserve --create-namespace --wait

# Install Kserve
helm upgrade --install kserve ./kserve-resources-v0.19.0.tgz \
  -n kserve --wait \
  --set kserve.controller.deploymentMode=RawDeployment \
  --set kserve.controller.gateway.disableIngressCreation=true \
  --set kserve.controller.image=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-kserve-controller \
  --set kserve.controller.rbacProxyImage=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-kube-rbac-proxy:v0.18.0 \
  --set kserve.controller.imagePullSecrets[0].name=${IMAGE_PULL_SECRET}

# Install KServe llmisvc crds
helm upgrade --install kserve-llmisvc-crd ./kserve-llmisvc-crd-v0.19.0.tgz -n kserve --create-namespace --wait

# Install KServe llmisvc
helm upgrade --install kserve-llmisvc-resources ./kserve-llmisvc-resources-v0.19.0.tgz \
  -n kserve --create-namespace --wait --set kserve.createSharedResources=false --set kserve.llmisvc.createGIECRDs=false \
  --set kserve.llmisvc.controller.image=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-llmisvc-controller \
  --set "kserve.llmisvc.controller.imagePullSecrets[0]=${IMAGE_PULL_SECRET}"

# Install OpenTelemetry Operator
helm upgrade --install opentelemetry-operator ./opentelemetry-operator-0.114.1.tgz \
  -n opentelemetry --create-namespace --wait \
  --set manager.image.repository=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-opentelemetry-operator \
  --set manager.collectorImage.repository=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-opentelemetry-collector-k8s \
  --set kubeRBACProxy.image.repository=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-kube-rbac-proxy \
  --set imagePullSecrets[0].name=${IMAGE_PULL_SECRET}

# Install CloudNative PG (not in airgapped bundle currently)
helm install cnpg cloudnative-pg \
  --repo https://cloudnative-pg.github.io/charts \
  --version 0.28.0 -n cnpg-system --create-namespace --wait

# Install LeaderWorkerSet
helm upgrade --install lws ./lws-0.8.0.tgz -n lws-system --create-namespace --wait \ 
--set "imagePullSecrets[0].name=${IMAGE_PULL_SECRET}" \ 
--set image.manager.repository=${IMAGE_REGISTRY_URL}/${PROJECT}/nai-lws 