#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

sleep 15

nkp create cluster nutanix -c workload02 \
-n kommander-default-workspace \
--endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
--insecure \
--control-plane-vcpus 8 \
--control-plane-memory 32 \
--worker-vcpus 16 \
--worker-memory 64 \
--control-plane-endpoint-ip $WL02_CONTROL_PLANE_VIP_ADDRESS \
--control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--control-plane-subnets $WL02_NUTANIX_SUBNET_NAME \
--csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
--kubernetes-service-load-balancer-ip-range $WL02_LB_IP_RANGE_STARTS-$WL02_LB_IP_RANGE_ENDS \
--worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--worker-subnets $WL02_NUTANIX_SUBNET_NAME \
--registry-mirror-url https://$REGISTRY_MIRROR_URL \
--ssh-public-key-file  ~/.ssh/id_rsa.pub \
--vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME

kubectl -n kommander-default-workspace label cluster workload02 infraId=$INFRA_PROVIDER_NAME

nkp get kubeconfig -c workload02 -n kommander-default-workspace > workload02.conf

kubectl --kubeconfig workload02.conf apply -f files_sc.yaml

kubectl --kubeconfig workload02.conf --namespace metallb-system patch ipaddresspool metallb --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/addresses/-",
    "value": "'"${WL02_LB_IP_RANGE_USERS_STARTS}-${WL02_LB_IP_RANGE_USERS_ENDS}"'"
  }
]'