#!/usr/bin/env bash
set -ex

# Create secret for certificates
kubectl create secret tls -n istio-system iep-cert --cert=$CERT --key=$KEY

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
      credentialName: iep-cert
EOF

# Patch catalog item in NKP with the endpoint URL
kubectl patch cm nai-ui -n ${NKP_WORKSPACE} -p '{"data":{"dashboardLink":"'${NAI_UI_ENDPOINT}'"}}'

# Patch configmaps NCN-104322
kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-nodeselector":"enabled"},"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}}}'
kubectl patch configmap config-autoscaler -n knative-serving --patch '{"data":{"enable-scale-to-zero":"false"},"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}}}'