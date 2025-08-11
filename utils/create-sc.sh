cat <<EOF | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
    name: nutanix-files
provisioner: csi.nutanix.com
parameters:
  dynamicProv: ENABLED
  nfsServerName: files
  nfsServer: files.ntnxlab.local
  csi.storage.k8s.io/provisioner-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/provisioner-secret-namespace: ntnx-system
  csi.storage.k8s.io/node-publish-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/node-publish-secret-namespace: ntnx-system
  csi.storage.k8s.io/controller-expand-secret-name: nutanix-csi-credentials-files
  csi.storage.k8s.io/controller-expand-secret-namespace: ntnx-system
  storageType: NutanixFiles
allowVolumeExpansion: true
EOF