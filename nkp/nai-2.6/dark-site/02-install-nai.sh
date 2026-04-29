#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure KServe is running
echo "Checking for Kserve"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve; do sleep 2; done

kubectl -n nai-system create secret docker-registry ${IMAGE_PULL_SECRET} \
  --docker-server=${NAI_IMAGE_REGISTRY} \
  --docker-username=${REGISTRY_USERNAME} \
  --docker-password=${REGISTRY_PASSWORD} \
  --docker-email=${REGISTRY_EMAIL} \
  --dry-run=client -o yaml | kubectl apply -f -

# Set up overrides
cat <<EOF > ~/darksite-nai-operators.yaml
global:
  imagePullSecrets:
    - name: ${IMAGE_PULL_SECRET}

naiRedis:
  naiRedisImage:
    name: ${NAI_IMAGE_REGISTRY}/nutanix/nai-redis

naiJobs:
  naiJobsImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-jobs

nai-clickhouse-operator:
  operator:
    image:
      registry: ${NAI_IMAGE_REGISTRY}
      repository: nutanix/nai-clickhouse-operator
  metrics:
    image:
      registry: ${NAI_IMAGE_REGISTRY}
      repository: nutanix/nai-clickhouse-metrics-exporter

ai-gateway-helm:
  extProc:
    image: 
      repository: ${NAI_IMAGE_REGISTRY}/nutanix/nai-ai-gateway-extproc
  controller:
    image:
      repository: ${NAI_IMAGE_REGISTRY}/nutanix/nai-ai-gateway-controller
EOF

cat <<EOF > ~/darksite-nai-core.yaml
global:
  imagePullSecrets:
    - name: ${IMAGE_PULL_SECRET}

defaultStorageClassName: ${NAI_DEFAULT_RWO_STORAGECLASS}
naiIepOperator:
  iepOperatorImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iep-operator

  modelProcessorImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-python-processor

  dataSourceProcessorImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-python-processor

  finetuneProcessorImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-finetuning

naiInferenceUi:
  naiUiImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-inference-ui

naiJobs:
  naiJobsImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-jobs

naiApi:
  storageClassName: ${NAI_API_RWX_STORAGECLASS}
  naiApiImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-api
  supportedTGIImage: ${NAI_IMAGE_REGISTRY}/nutanix/nai-tgi
  supportedKserveRuntimeImage: ${NAI_IMAGE_REGISTRY}/nutanix/nai-kserve-huggingfaceserver
  eppImage: ${NAI_IMAGE_REGISTRY}/nutanix/nai-epp-inference-scheduler
  supportedVLLMImage: ${NAI_IMAGE_REGISTRY}/nutanix/nai-vllm
  supportedKserveCustomModelServerRuntimeImage: ${NAI_IMAGE_REGISTRY}/nutanix/nai-kserve-custom-model-server

naiDatabase:
  naiDbImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-postgres:16.1-alpine

naiIam:
  iamProxy:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iam-proxy

  iamProxyControlPlane:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iam-proxy-control-plane

  iamUi:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iam-ui

  iamUserAuthn:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iam-user-authn

  iamThemis:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iam-themis

  iamThemisBootstrap:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-iam-bootstrap

naiLabs:
  labsImage:
    image: ${NAI_IMAGE_REGISTRY}/nutanix/nai-rag-app

nai-clickhouse-keeper:
  clickhouseKeeper:
    storage:
      storageClass: ${NAI_DEFAULT_RWO_STORAGECLASS}
    image:
      registry: ${NAI_IMAGE_REGISTRY}
      repository: nutanix/nai-clickhouse-keeper

oauth2-proxy:
  image:
    repository: ${NAI_IMAGE_REGISTRY}/nutanix/nai-oauth2-proxy

nai-clickhouse-server:
  clickhouse:
    storage:
      storageClass: ${NAI_DEFAULT_RWO_STORAGECLASS}
    image:
      registry: ${NAI_IMAGE_REGISTRY}
      repository: nutanix/nai-clickhouse-server
    initContainers:
      addUdf:
        image:
          registry: ${NAI_IMAGE_REGISTRY}
          repository: nutanix/nai-clickhouse-udf
      waitForKeeper:
        image:
          registry: ${NAI_IMAGE_REGISTRY}
          repository: nutanix/nai-jobs

nai-clickhouse-schemas:
  image:
    registry: ${NAI_IMAGE_REGISTRY}
    repository: nutanix/nai-clickhouse-schemas

naiMonitoring:
  opentelemetry:
    storageClassName: ${NAI_API_RWX_STORAGECLASS}
    collectorImage: ${NAI_IMAGE_REGISTRY}/nutanix/nai-opentelemetry-collector-contrib:0.141.0
    targetAllocator:
      image:
        repository: ${NAI_IMAGE_REGISTRY}/nutanix/nai-target-allocator
  nodeExporter:
    serviceMonitor:
      namespaceSelector:
        matchNames:
          - ${NKP_WORKSPACE_NAMESPACE}
  dcgmExporter:
    serviceMonitor:
      namespaceSelector:
        matchNames:
          - ${NKP_WORKSPACE_NAMESPACE}
EOF

# Install nai-operators
helm upgrade --install nai-operators ./nai-operators-2.6.0.tgz \
  --version=2.6.0 \
  -n nai-system --create-namespace --wait \
  --set "naiAIGateway.enabled=true" \
  --insecure-skip-tls-verify \
  -f ./darksite-nai-operators.yaml

# Wait until it's done installing
echo -n "Waiting for redis-standalone to be created in namespace nai-system"
until kubectl wait --for condition=ready pods -l app=redis-standalone -n nai-system >/dev/null 2>&1; do echo -n "."; sleep 2; done; echo " Done"
echo -n "Waiting for nai-clickhouse-operator to be created in namespace nai-system"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=nai-clickhouse-operator -n nai-system >/dev/null 2>&1; do echo -n "."; sleep 2; done; echo " Done"

# Install nai-core with AI Gateway enabled
helm upgrade --install nai-core ./nai-core-2.6.0.tgz \
  --version=2.6.0 \
  -n nai-system --create-namespace --wait \
  --set "naiAIGateway.enabled=true" \
  --insecure-skip-tls-verify \
  -f ./darksite-nai-core.yaml