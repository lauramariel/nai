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
    ${GPU_POOL} --dry-run -o yaml > gpu-nodepool.yaml
    
# modify yaml file to add GPU specifications
yq e '(.spec.topology.workers.machineDeployments[] | select(.name == "gpu-nodepool").variables.overrides[] | select(.name == "workerConfig").value.nutanix.machineDetails) += {"gpus": [{"type": "name", "name": strenv(GPU_NAME)}]}' -i gpu-nodepool.yaml
    
kubectl apply -f gpu-nodepool.yaml