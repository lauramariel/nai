#!/usr/bin/env bash
# Create secret for CSI driver
# Create storage class
# Create secret for certificates
# Patch gateway to use certificate

set -ex

# Create secret for CSI driver
kubectl create secret generic nutanix-csi-credentials-files \
-n ntnx-system --from-literal=key=${FILES_CREDS_STRING} \
--dry-run -o yaml | kubectl apply -f -

# Create storage class
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

# Create secret for certificates
kubectl create secret tls -n istio-system iep-cert --cert=$CERT --key=$KEY

# Patch gateway to use certificate
kubectl patch gateway knative-ingress-gateway -n knative-serving --type merge --patch-file=/dev/stdin <<EOF
spec:
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: true
  - hosts:
    - '*'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: iep-cert
EOF
