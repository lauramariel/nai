#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

cat <<EOF > ~/files_sc.yaml
apiVersion: v1
kind: Secret
metadata:
  name: nutanix-csi-credentials-files
  namespace: ntnx-system
type: Opaque
stringData:
# Provide Nutanix Prism Element credentials which is a default UI credential separated by colon in "key:".
# Provide Nutanix File Server credentials which is a REST API user created on File server UI separated by colon in "files-key:".
  key: "$PE_VIP_ADDRESS:$NUTANIX_PORT:$NUTANIX_USER:$NUTANIX_PASSWORD"
  files-key: "$NUS_FS_NAME.$DOMAIN:$NUS_FS_API_USER:$NUS_FS_API_PASSWORD"
---
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-files
parameters:
  dynamicProv: ENABLED
  nfsServerName: $NUS_FS_NAME
  nfsServer: $NUS_FS_NAME.$DOMAIN
  csi.storage.k8s.io/controller-expand-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/controller-expand-secret-namespace: ntnx-system
  csi.storage.k8s.io/node-publish-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/node-publish-secret-namespace: ntnx-system
  csi.storage.k8s.io/provisioner-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/provisioner-secret-namespace: ntnx-system
  storageType: NutanixFiles
provisioner: csi.nutanix.com
EOF