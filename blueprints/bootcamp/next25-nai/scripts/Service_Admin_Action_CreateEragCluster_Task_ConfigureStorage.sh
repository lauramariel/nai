#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Set NFS storage class as default in the erag cluster
kubectl --kubeconfig /home/nutanix/erag.conf patch storageclass nutanix-files -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' && kubectl --kubeconfig /home/nutanix/erag.conf patch storageclass nutanix-volume -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
