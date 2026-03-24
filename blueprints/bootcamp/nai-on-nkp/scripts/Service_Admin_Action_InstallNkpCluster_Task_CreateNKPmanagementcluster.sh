#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env
source ~/.secrets

time nkp create cluster nutanix -c $CLUSTER_NAME \
--bootstrap-cluster-image $REGISTRY_MIRROR_URL/mesosphere/konvoy-bootstrap:$NKP_VERSION \
--endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
--insecure \
--control-plane-replicas 1 \
--control-plane-vcpus 8 \
--control-plane-memory 32 \
--worker-replicas $NO_OF_WORKER_NODES \
--worker-vcpus 32 \
--worker-memory 64 \
--vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
--kubernetes-service-load-balancer-ip-range $MGMT_LB_IP_RANGE_STARTS-$MGMT_LB_IP_RANGE_ENDS \
--control-plane-endpoint-ip $CONTROL_PLANE_VIP_ADDRESS \
--control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--control-plane-subnets $NUTANIX_SUBNET_NAME \
--worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
--worker-subnets $NUTANIX_SUBNET_NAME \
--csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
--registry-mirror-url http://$REGISTRY_MIRROR_URL \
--registry-mirror-username $REGISTRY_USERNAME \
--registry-mirror-password $REGISTRY_PASSWORD \
--ssh-public-key-file  ~/.ssh/id_rsa.pub \
--csi-hypervisor-attached-volumes=false \
--self-managed

mkdir -p ~/.kube
cp $CLUSTER_NAME.conf ~/.kube/config