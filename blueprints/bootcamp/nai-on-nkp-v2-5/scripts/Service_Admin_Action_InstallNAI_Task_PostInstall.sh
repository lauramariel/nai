#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure nai-core is up
until kubectl wait pod --all --for=condition=Ready --field-selector=status.phase!=Succeeded --namespace=nai-system; do sleep 2; done

GATEWAY_IP=$(kubectl get gateway -o jsonpath='{.items[].status.addresses[].value}' -n nai-system)
NAI_UI_ENDPOINT="https://${GATEWAY_IP//./-}.sslip.nutanixdemo.com"
NAI_UI_HOSTNAME="${GATEWAY_IP//./-}.sslip.nutanixdemo.com"
# Create secret for certificates

# get certs
mkdir -p $HOME/certs
wget -O $HOME/certs/fullchain1.pem http://10.55.251.38/workshop_staging/tradeshows/configuration/certificates/sslip.nutanixdemo.com/fullchain1.pem 
wget -O $HOME/certs/privkey1.pem http://10.55.251.38/workshop_staging/tradeshows/configuration/certificates/sslip.nutanixdemo.com/privkey1.pem

CERT_PATH="$HOME/certs/fullchain1.pem"
KEY_PATH="$HOME/certs/privkey1.pem"
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

cat <<EOF >> ~/.env
export NAI_UI_ENDPOINT="$NAI_UI_ENDPOINT"
EOF

echo "NAI_UI_ENDPOINT=$NAI_UI_ENDPOINT"