#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure KServe is running
echo "Checking for Kserve"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve; do sleep 2; done

kubectl create ns nai-system --dry-run=client -o yaml | kubectl apply -f -
export IMAGE_PULL_SECRET="registry-image-pull-secret"
kubectl -n nai-system create secret docker-registry ${IMAGE_PULL_SECRET} \
  --docker-server=${IMAGE_REGISTRY_URL} \
  --docker-username=${REGISTRY_USERNAME} \
  --docker-password=${REGISTRY_PASSWORD} \
  --docker-email=${REGISTRY_EMAIL} \
  --dry-run=client -o yaml | kubectl apply -f -

# Set up overrides
export REGISTRY="${IMAGE_REGISTRY_URL}" # to match template
envsubst < templates/darksite-nai-operators.yaml.template > darksite-nai-operators.yaml
envsubst < templates/darksite-nai-core.yaml.template > darksite-nai-core.yaml

# Install nai-operators
helm upgrade --install nai-operators ./nai-operators-2.7.0.tgz \
  --version=2.7.0 \
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
helm upgrade --install nai-core ./nai-core-2.7.0.tgz \
  --version=2.7.0 \
  -n nai-system --create-namespace --wait \
  --set "naiAIGateway.enabled=true" \
  --set "naiLabs.enabled=true" \
  --insecure-skip-tls-verify \
  -f ./darksite-nai-core.yaml

# Optional flags
# --set "naiLabs.enabled=true"
# --set "gateway.replicaCount=<Number_of_replicas>"
# --set "naiApi.replicaCount=<Number_of_replicas>"
# --set "naiDatabase.postgresConfig.maxConnections=<Number_of_Connections>" (default is 1000)