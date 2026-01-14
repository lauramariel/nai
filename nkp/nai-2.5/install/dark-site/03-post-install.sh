#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure nai-core is up
until kubectl wait pod --all --for=condition=Ready --field-selector=status.phase!=Succeeded --namespace=nai-system; do sleep 2; done

# Update paths based on where your cert and key are saved locally
CERT_PATH="$HOME/certs/fullchain1.pem"
KEY_PATH="$HOME/certs/privkey1.pem"

# Create secret
CERT_NAME="nai-cert"
echo "Creating secret $CERT_NAME for certificate"
kubectl create secret tls -n nai-system $CERT_NAME --cert=$CERT_PATH --key=$KEY_PATH
kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-cert"}]'

# patch gateway to point to envoyproxy
kubectl patch gatewayclass nai-gatewayclass \
  --type merge \
  -p '{
    "spec": {
      "parametersRef": {
        "group": "gateway.envoyproxy.io",
        "kind": "EnvoyProxy",
        "name": "nai-envoyproxy",
        "namespace": "envoy-gateway-system"
      }
    }
  }'

# Create clusterrole to fetch metrics
kubectl patch clusterrole nai-otel-role --type='json' -p='[
  {
    "op": "add",
    "path": "/rules/-",
    "value": {
      "apiGroups": [""],
      "resources": ["services/kube-prometheus-stack-prometheus-node-exporter"],
      "verbs": ["get"]
    }
  }
]'

kubectl patch servicemonitor nai-node-exporter-monitor -n nai-system --type='json' -p='[
  {"op": "add", "path": "/spec/endpoints/0/bearerTokenFile", "value": "/var/run/secrets/kubernetes.io/serviceaccount/token"},
  {"op": "replace", "path": "/spec/endpoints/0/scheme", "value": "https"},
  {"op": "add", "path": "/spec/endpoints/0/tlsConfig", "value": {"insecureSkipVerify": true}}
]'

# cat <<EOF >> ~/.env
# export NAI_UI_ENDPOINT="$NAI_UI_ENDPOINT"
# EOF

# echo "NAI_UI_ENDPOINT=$NAI_UI_ENDPOINT"