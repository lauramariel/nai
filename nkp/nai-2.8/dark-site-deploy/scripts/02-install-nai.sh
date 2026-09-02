#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure KServe is running
echo "Checking for Kserve"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve; do sleep 2; done

# Set up overrides
envsubst < templates/darksite-nai-operators.yaml.template > darksite-nai-operators.yaml
envsubst < templates/darksite-nai-core.yaml.template > darksite-nai-core.yaml

# Install nai-operators
helm upgrade --install nai-operators ./nai-operators-2.8.0.tgz \
  -n nai-system --create-namespace --wait --timeout 15m -f ./darksite-nai-operators.yaml

# Wait until it's done installing
# echo -n "Waiting for redis-standalone to be created in namespace nai-system"
# until kubectl wait --for condition=ready pods -l app=redis-standalone -n nai-system >/dev/null 2>&1; do echo -n "."; sleep 2; done; echo " Done"
# echo -n "Waiting for nai-clickhouse-operator to be created in namespace nai-system"
# until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=nai-clickhouse-operator -n nai-system >/dev/null 2>&1; do echo -n "."; sleep 2; done; echo " Done"

# Install nai-core with AI Gateway enabled
helm upgrade --install nai-core ./nai-core-2.8.0.tgz -n nai-system --create-namespace --wait --timeout 15m \
  --set "naiLabs.enabled=true" \
  -f ./darksite-nai-core.yaml

# Optional flags
# --set "naiLabs.enabled=true"
# --set "gateway.replicaCount=<Number_of_replicas>"
# --set "naiApi.replicaCount=<Number_of_replicas>"
# --set "naiDatabase.postgresConfig.maxConnections=<Number_of_Connections>" (default is 1000)