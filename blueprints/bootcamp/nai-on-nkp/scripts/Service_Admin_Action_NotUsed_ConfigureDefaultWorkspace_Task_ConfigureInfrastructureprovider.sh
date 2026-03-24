#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

kubectl create secret generic $INFRA_PROVIDER_NAME -n kommander-default-workspace \
  --from-literal=prismURL=https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
  --from-literal=username=$NUTANIX_USER \
  --from-literal=password=$NUTANIX_PASSWORD \
  --from-literal=additionalTrustBundle="" \
  --from-literal=insecure=true
kubectl label secret $INFRA_PROVIDER_NAME -n kommander-default-workspace dkp-infrastructure-provider-type=nutanix-secret