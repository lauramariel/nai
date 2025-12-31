#!/usr/bin/env bash
set -euo pipefail
# set -x
IFS=$'\n\t'

source ~/.secrets
source ~/.env

export INSTANCE="n8n"
# From https://nai.howntnx.win/nkp_tutorials/nkp_mcp_lab/nkp_nai_n8n/#install-n8n

mkdir $HOME/n8n
cd $HOME/n8n
git clone https://github.com/n8n-io/n8n-hosting.git
cd n8n-hosting/kubernetes/

# Needed for MCP server
yq -i e '.spec.template.spec.containers[0].env += [{"name": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE", "value":"true"}]' n8n-deployment.yaml

# Install Postgres 13, default is 11 which doesn't have required extension
yq -i e '.spec.template.spec.containers[0].image="postgres:13"' postgres-deployment.yaml

# Install
kubectl create namespace ${INSTANCE} --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f .

# Configure Ingress
export INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[].ip}" && echo)
export SSLIP_HOSTNAME="${INSTANCE}-${INGRESS_IP//./-}.sslip.nutanixdemo.com"

# use the existing certificate
kubectl get secret -n nai-system nai-cert -o yaml | sed "s/namespace: nai-system/namespace: ${INSTANCE}/g" | kubectl apply -f -
kubectl get secret nai-cert -n ${INSTANCE}

kubectl apply -f -<<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ingress
  namespace: n8n                    # Same namespace as your chat app service
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    nginx.ingress.kubernetes.io/enable-buffering: "false"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Connection '';
spec:
  ingressClassName: nginx
  rules:
  - host: ${SSLIP_HOSTNAME}
    http:
      paths:
      - backend:
          service:
            name: n8n
            port: 
              number: 5678
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - ${SSLIP_HOSTNAME}
    secretName: nai-cert
EOF