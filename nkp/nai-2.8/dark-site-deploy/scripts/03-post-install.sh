#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Make sure nai-core is up
until kubectl wait pod --all --for=condition=Ready --field-selector=status.phase!=Succeeded --namespace=nai-system; do sleep 2; done

# Update paths based on where your cert and key are saved locally
CERT_PATH="$HOME/certs/fullchain.pem"
KEY_PATH="$HOME/certs/privkey.pem"

# Create secret and patch gateway with secret
CERT_NAME="nai-cert"
echo "Creating secret $CERT_NAME for certificate"
kubectl create secret tls $CERT_NAME \
  -n nai-system \
  --cert=$CERT_PATH \
  --key=$KEY_PATH \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-cert"}]'