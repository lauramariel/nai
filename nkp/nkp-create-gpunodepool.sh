#!/usr/bin/env bash

set -ex
nkp create nodepool nutanix \
    --cluster-name ${CLUSTER_NAME} \
    --prism-element-cluster ${NUTANIX_PRISM_ELEMENT_CLUSTER_NAME} \
    --subnets ${NUTANIX_SUBNET_NAME} \
    --vm-image ${NKP_UBUNTU_IMAGE} \
    --disk-size ${GPU_NODE_DISK_SIZE_GIB} \
    --memory ${GPU_NODE_MEMORY_GIB} \
    --vcpus ${GPU_NODE_VCPUS} \
    --cores-per-vcpu ${GPU_NODE_CORES_PER_VCPU} \
    --replicas ${GPU_REPLICA_COUNT} \
    --wait \
    --verbose 4 \
    --gpu-count 1 \
    --gpu-name "${GPU_NAME}" \
    ${GPU_POOL}
