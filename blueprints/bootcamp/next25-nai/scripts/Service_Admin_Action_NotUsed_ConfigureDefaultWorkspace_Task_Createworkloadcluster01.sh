#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

nkp create cluster nutanix -c workload01 \
-n kommander-default-workspace \
--endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
--insecure \
--control-plane-vcpus 8 \
--control-plane-memory 32 \
--worker-vcpus 16 \
--worker-memory 64 \
--control-plane-endpoint-ip $WL01_CONTROL_PLANE_VIP_ADDRESS \
--control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--control-plane-subnets $WL01_NUTANIX_SUBNET_NAME \
--csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
--kubernetes-service-load-balancer-ip-range $WL01_LB_IP_RANGE_STARTS-$WL01_LB_IP_RANGE_ENDS \
--worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--worker-subnets $WL01_NUTANIX_SUBNET_NAME \
--registry-mirror-url https://$REGISTRY_MIRROR_URL \
--ssh-public-key-file  ~/.ssh/id_rsa.pub \
--vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME

kubectl -n kommander-default-workspace label cluster workload01 infraId=$INFRA_PROVIDER_NAME

nkp get kubeconfig -c workload01 -n kommander-default-workspace > workload01.conf

kubectl --kubeconfig workload01.conf apply -f files_sc.yaml

kubectl --kubeconfig workload01.conf --namespace metallb-system patch ipaddresspool metallb --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/addresses/-",
    "value": "'"${WL01_LB_IP_RANGE_USERS_STARTS}-${WL01_LB_IP_RANGE_USERS_ENDS}"'"
  }
]'