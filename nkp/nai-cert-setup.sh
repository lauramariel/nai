#!/bin/bash

## Using your own TLS cert that was generated for your FQDN
bring_cert() {
read -p "Provide full path to certificate file: " CERT_PATH
read -p "Provide full path to private key file: " KEY_PATH

if [[ ! -e $CERT_PATH || ! -e $KEY_PATH ]]; then
    echo "ERROR: One or both files do not exist." >&2
    exit 1
fi

echo "Creating secret iep-cert for certificate"

# Create secret for certificates
kubectl create secret tls -n istio-system iep-cert --cert=$CERT --key=$KEY
patch_gateway "iep-cert"
}

## Using Cert-Manager and provided DNS service
use_sslip_io() {
INGRESS_HOST=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
NAI_UI_ENDPOINT="https://nai.${INGRESS_HOST}.sslip.io"

cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: nai-cert
  namespace: istio-system
spec:
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  secretName: nai-cert
  commonName: ${NAI_UI_ENDPOINT}
  dnsNames:
  - ${NAI_UI_ENDPOINT}
  ipAddresses:
  - ${INGRESS_HOST}
EOF

patch_gateway "nai-cert"
echo "NAI_UI_ENDPOINT is ${NAI_UI_ENDPOINT}"
}

## Using built in self signed cert (not recommended)
self_signed_cert() {    
# use existing cert provided by NAI
patch_gateway "nai-self-signed-cert"
export NAI_UI_ENDPOINT="https://$(kubectl get svc istio-ingressgateway -n istio-system -ojsonpath='{.status.loadBalancer.ingress[0].ip}' | grep -v '^$' || kubectl get svc istio-ingressgateway -n istio-system -ojsonpath='{.status.loadBalancer.ingress[0].hostname}')/"
echo "NAI_UI_ENDPOINT is $NAI_UI_ENDPOINT"
}

patch_gateway() {
echo "Patching gateway to use certificate"

SECRET_NAME=$1

# Patch gateway to use certificate
kubectl patch gateway knative-ingress-gateway -n knative-serving --type merge --patch-file=/dev/stdin <<EOF
spec:
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: true 
  - hosts:
    - '*'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: $SECRET_NAME
EOF
}

echo "Choose an option:"
echo "1) Bring your own cert"
echo "2) Create cert with cert-manager using sslip.io DNS service"
echo "3) Use built-in self-signed cert"
read -p "Enter your choice (1-3): " choice

case $choice in
    1) bring_cert ;;
    2) use_sslip_io ;;
    3) self_signed_cert ;;
    *) echo "Invalid option. Please enter 1, 2, or 3." ;;
esac

