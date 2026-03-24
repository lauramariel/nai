#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure KServe is running
echo "Checking for Kserve"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve; do sleep 2; done

# Pull chart from private registry
#export NAI_IMAGE_REGISTRY="registry.nutanixdemo.com"
#helm pull oci://$NAI_IMAGE_REGISTRY/nai/nai-core --version 2.5.0 --untar=true

# We already pulled the nai-core chart in the previous step

# Skip the image tag checks for private registry
#PATCH_DATA=$(cat <<EOF
#{"data":{"registries-skipping-tag-resolving":"$NAI_IMAGE_REGISTRY"}}
#EOF
#)
#kubectl patch configmap config-deployment -n knative-serving --type merge -p "$PATCH_DATA"

# Set up overrides
cat <<EOF > ~/nai-operators-override-values.yaml 
imagePullSecret:
  credentials:
    registry: $NAI_IMAGE_REGISTRY
naiRedis:
  naiRedisImage:
    name: $NAI_IMAGE_REGISTRY/nutanix/nai-redis
naiJobs:
  naiJobsImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-jobs
nai-clickhouse-operator:
  operator:
    image:
      registry: $NAI_IMAGE_REGISTRY/nutanix
      repository: nai-clickhouse-operator
  metrics:
    image:
      registry: $NAI_IMAGE_REGISTRY/nutanix
      repository: nai-clickhouse-metrics-exporter
ai-gateway-helm:
  extProc:
    image:
      repository: $NAI_IMAGE_REGISTRY/nutanix/nai-ai-gateway-extproc
      tag: c4f26a8
  controller:
    image:
      repository: $NAI_IMAGE_REGISTRY/nutanix/nai-ai-gateway-controller
      tag: c4f26a8
EOF

cat <<EOF > ~/nai-core-override-values.yaml
imagePullSecret:
  credentials:
    registry: $NAI_IMAGE_REGISTRY
naiIepOperator:
  iepOperatorImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iep-operator
  modelProcessorImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-model-processor
naiInferenceUi:
  naiUiImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-inference-ui
naiJobs:
  naiJobsImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-jobs
naiApi:
  naiApiImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-api
  logger:
    logLevel: debug
  supportedTGIImage: $NAI_IMAGE_REGISTRY/nutanix/nai-tgi
  supportedKserveRuntimeImage: $NAI_IMAGE_REGISTRY/nutanix/nai-kserve-huggingfaceserver
  supportedVLLMImage: $NAI_IMAGE_REGISTRY/nutanix/nai-vllm
  supportedKserveCustomModelServerRuntimeImage: $NAI_IMAGE_REGISTRY/nutanix/nai-kserve-custom-model-server
naiIam:
  iamProxy:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iam-proxy
  iamProxyControlPlane:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iam-proxy-control-plane
  iamUi:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iam-ui
  iamUserAuthn:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iam-user-authn
  iamThemis:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iam-themis
  iamThemisBootstrap:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-iam-bootstrap
naiLabs:
  labsImage:
    image: $NAI_IMAGE_REGISTRY/nutanix/nai-rag-app
nai-clickhouse-keeper:
  clickhouseKeeper:
    image:
      registry: $NAI_IMAGE_REGISTRY/nutanix
      repository: nai-clickhouse-keeper
oauth2-proxy:
  image:
    repository: $NAI_IMAGE_REGISTRY/nutanix/nai-oauth2-proxy
nai-clickhouse-server:
  clickhouse:
    image:
      registry: $NAI_IMAGE_REGISTRY/nutanix
      repository: nai-clickhouse-server
    initContainers:
      addUdf:
        image:
          registry: $NAI_IMAGE_REGISTRY/nutanix
          repository: nai-clickhouse-udf
      waitForKeeper:
        image:
          registry: $NAI_IMAGE_REGISTRY/nutanix
          repository: nai-jobs
nai-clickhouse-schemas:
  image:
    registry: $NAI_IMAGE_REGISTRY/nutanix
    repository: nai-clickhouse-schemas
naiMonitoring:
  opentelemetry:
    collectorImage: $NAI_IMAGE_REGISTRY/nutanix/nai-opentelemetry-collector-contrib:0.136.0
    targetAllocator:
      image:
        repository: $NAI_IMAGE_REGISTRY/nutanix/nai-target-allocator
EOF

# Install nai-operators
helm install nai-operators ./nai-operators-2.5.0.tgz --version=2.5.0  -n nai-system --create-namespace --wait \
        --insecure-skip-tls-verify -f nai-operators-override-values.yaml

# Wait until it's done installing
echo -n "Waiting for redis-standalone to be created in namespace nai-system"
until kubectl wait --for condition=ready pods -l app=redis-standalone -n nai-system >/dev/null 2>&1; do echo -n "."; sleep 2; done; echo " Done"
echo -n "Waiting for nai-clickhouse-operator to be created in namespace nai-system"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=nai-clickhouse-operator -n nai-system >/dev/null 2>&1; do echo -n "."; sleep 2; done; echo " Done"

# Install nai-core
helm install nai-core ./nai-core-2.5.0.tgz --version=2.5.0 -n nai-system --create-namespace --wait \
    --insecure-skip-tls-verify \
    --set naiApi.storageClassName=nutanix-files \
    --set naiMonitoring.opentelemetry.storageClassName=nutanix-files \
    --set defaultStorageClassName=nutanix-volume \
    --set naiMonitoring.nodeExporter.serviceMonitor.namespaceSelector.matchNames[0]=$NKP_NAMESPACE \
    --set naiMonitoring.dcgmExporter.serviceMonitor.namespaceSelector.matchNames[0]=$NKP_NAMESPACE \
    --set "nai-clickhouse-keeper.clickhouseKeeper.resources.limits.memory=1Gi" \
	--set "nai-clickhouse-keeper.clickhouseKeeper.resources.requests.memory=1Gi" \
    -f nai-core-override-values.yaml