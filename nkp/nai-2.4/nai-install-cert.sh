#!/bin/bash

## Using your own TLS cert that was generated for your FQDN
bring_cert() {
read -p "Provide full path to certificate file: " CERT_PATH
read -p "Provide full path to private key file: " KEY_PATH

if [[ ! -e $CERT_PATH || ! -e $KEY_PATH ]]; then
    echo "ERROR: One or both files do not exist." >&2
    exit 1
fi

echo "Creating secret nai-ingress-certificate for certificate"

# Create secret for certificates
kubectl create secret tls nai-ingress-certificate -n nai-system --cert=$CERT_PATH --key=$KEY_PATH

# Patch gateway to use certificate
kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' --patch-file=/dev/stdin <<EOF
[
  {
    "op": "replace",
    "path": "/spec/listeners/1/tls/certificateRefs/0/name",
    "value": "$SECRET_NAME"
  }
]
EOF
