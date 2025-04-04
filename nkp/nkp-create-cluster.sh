#!/usr/bin/env bash

set -ex
nkp create cluster nutanix -c $CLUSTER_NAME \
    --kind-cluster-image $REGISTRY_MIRROR_URL/mesosphere/konvoy-bootstrap:v$NKP_VERSION \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    --control-plane-replicas 3 \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --ssh-public-key-file ${SSH_PUBLIC_KEY} \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    --worker-replicas 4 \
    --csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
    --registry-mirror-url http://$REGISTRY_MIRROR_URL \
    --control-plane-disk-size 150 \
    --control-plane-memory ${CONTROL_PLANE_MEMORY_GIB} \
    --control-plane-vcpus ${CONTROL_PLANE_VCPUS} \
    --control-plane-cores-per-vcpu ${CONTROL_PLANE_CORES_PER_VCPU} \
    --worker-disk-size ${WORKER_DISK_SIZE_GIB} \
    --worker-memory ${WORKER_MEMORY_GIB} \
    --worker-vcpus ${WORKER_VCPUS} \
    --worker-cores-per-vcpu ${WORKER_CORES_PER_VCPU} \
    --kubernetes-version 1.30.5 \
    --self-managed \
    # --dry-run \
    # --registry-url http://registry.nutanixdemo.com/nai \
    # --output yaml
