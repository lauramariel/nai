#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# TODO: make sure ingress is up

source ~/.env

# Make sure the istio-system namespace is up
#until kubectl get namespace istio-system &>/dev/null; do echo "Waiting for namespace istio-system";  sleep 2; done

# INSTANCE=flowise-user#

echo "Creating $NO_OF_USERS flowise instances"

for i in $(seq 1 $NO_OF_USERS)
do
  export INSTANCE="flowise-adminuser0$i"
  export INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[].ip}" && echo)
  export SSLIP_HOSTNAME="${INSTANCE}-${INGRESS_IP//./-}.sslip.nutanixdemo.com"

  kubectl create namespace ${INSTANCE} --dry-run=client -o yaml | kubectl apply -f -

  # use the existing certificate
  kubectl get secret -n nai-system nai-cert -o yaml | sed "s/namespace: nai-system/namespace: ${INSTANCE}/g" | kubectl apply -f -
  kubectl get secret nai-cert -n ${INSTANCE}

  # install flowise
  helm repo add cowboysysop https://cowboysysop.github.io/charts/
  helm repo update cowboysysop

  time helm upgrade --install flowise cowboysysop/flowise --version 3.11.3 \
    --namespace ${INSTANCE} \
    --set global.imageRegistry="${REGISTRY_MIRROR_URL}" \
    --set image.tag="2.2.7" \
    --set ingress.enabled=true \
    --set ingress.ingressClassName="nginx" \
    --set ingress.hosts[0].host="${SSLIP_HOSTNAME}" \
    --set ingress.hosts[0].paths[0]="/" \
    --set ingress.tls[0].secretName="nai-cert" \
    --set ingress.tls[0].hosts[0]="${SSLIP_HOSTNAME}" \
    --wait
 done