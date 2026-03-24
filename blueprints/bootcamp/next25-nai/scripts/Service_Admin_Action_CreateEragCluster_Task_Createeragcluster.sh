#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [[ @@{ERAG}@@ != "true" ]]; then
    echo "eRAG marked False or unset, skipping"
    exit 0
fi

source ~/.env
source ~/.secrets

nkp create cluster nutanix -c erag \
-n kommander-default-workspace \
--endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
--insecure \
--control-plane-replicas 1 \
--control-plane-vcpus 8 \
--control-plane-memory 32 \
--worker-replicas 3 \
--worker-vcpus 32 \
--worker-memory 64 \
--control-plane-endpoint-ip $WL01_CONTROL_PLANE_VIP_ADDRESS \
--control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--control-plane-subnets $WL01_NUTANIX_SUBNET_NAME \
--csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
--kubernetes-service-load-balancer-ip-range $WL01_LB_IP_RANGE_STARTS-$WL01_LB_IP_RANGE_ENDS \
--worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--worker-subnets $WL01_NUTANIX_SUBNET_NAME \
--registry-mirror-url https://$REGISTRY_MIRROR_URL \
--registry-mirror-username $REGISTRY_USERNAME \
--registry-mirror-password $REGISTRY_PASSWORD \
--ssh-public-key-file  ~/.ssh/id_rsa.pub \
--vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME

cd $HOME

kubectl -n kommander-default-workspace label cluster erag infraId=$INFRA_PROVIDER_NAME

nkp get kubeconfig -c erag -n kommander-default-workspace > erag.conf

kubectl --kubeconfig erag.conf apply -f files_sc.yaml

kubectl --kubeconfig erag.conf --namespace metallb-system patch ipaddresspool metallb --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/addresses/-",
    "value": "'"${WL01_LB_IP_RANGE_USERS_STARTS}-${WL01_LB_IP_RANGE_USERS_ENDS}"'"
  }
]'