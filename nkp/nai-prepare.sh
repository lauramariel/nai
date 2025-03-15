#!/usr/bin/env bash

set -ex

# Create app catalog
nkp create catalog nutanix-apps-catalog -w $NKP_WORKSPACE \
--branch main \
--url https://github.com/nutanix-cloud-native/nkp-nutanix-product-catalog

# Create secret for CSI driver
kubectl create secret generic nutanix-csi-credentials-files \
-n ntnx-system --from-literal=key=${PE_CREDS_STRING} \
--from-literal=files-key=${FILES_CREDS_STRING} \
--dry-run=client -o yaml | kubectl apply -f -

# Create storage class - dynamic provisioning
cat <<EOF | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
    name: nai-nfs-storage
provisioner: csi.nutanix.com
parameters:
  dynamicProv: ENABLED
  nfsServerName: $NFS_SERVER_NAME
  nfsServer: $NFS_SERVER_FQDN
  csi.storage.k8s.io/provisioner-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/provisioner-secret-namespace: ntnx-system
  csi.storage.k8s.io/node-publish-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/node-publish-secret-namespace: ntnx-system
  csi.storage.k8s.io/controller-expand-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/controller-expand-secret-namespace: ntnx-system
  storageType: NutanixFiles
allowVolumeExpansion: true
EOF

# Static provisioning example
# cat <<EOF | kubectl apply -f -
# apiVersion: storage.k8s.io/v1
# kind: StorageClass
# metadata:
#   name: nai-nfs-storage
# parameters:
#   nfsPath: $NFS_PATH
#   nfsServer: $NFS_SERVER_FQDN
#   storageType: NutanixFiles
# provisioner: csi.nutanix.com
# reclaimPolicy: Delete
# volumeBindingMode: Immediate
# EOF
