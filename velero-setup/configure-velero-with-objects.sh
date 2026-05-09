# From NKP doc
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform-v2_17:top-velero-with-nutanix-prep-environment-t.html

# Update velero.env to match your environment
source ~/velero.env

# Create secret
kubectl --kubeconfig=${CLUSTER_NAME}.conf apply -f - <<EOF 
apiVersion: v1
kind: Secret
metadata:
  name: ${NUTANIX_OBJECTS_SECRET}
  namespace: ${NKP_WORKSPACE_NAMESPACE}  
type: Opaque
stringData:
  aws: |
    [${AWS_PROFILE}]
    aws_access_key_id = ${NUTANIX_OBJECTS_ACCESS_KEY_ID}
    aws_secret_access_key = ${NUTANIX_OBJECTS_SECRET_ACCESS_KEY}
EOF

# Create configmap for overrides
kubectl --kubeconfig ${CLUSTER_NAME}.conf apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${NKP_WORKSPACE_NAMESPACE}
  name: velero-overrides
data:
  values.yaml: |
    credentials:
      extraSecretRef: ""
    configuration:
      features: EnableCSI
      backupStorageLocation:
        - name: ${BSL_NAME}
          bucket: ${BUCKET}
          provider: "aws" 
          default: true
          config:
            region: us-east-1
            s3ForcePathStyle: "true"
            insecureSkipTLSVerify: "true"
            s3Url: "https://${NUTANIX_OBJECTS_HOST}"
            # profile should be set to the AWS profile name mentioned in the secret
            profile: ${AWS_PROFILE}
          credential:
            key: aws
            name: ${NUTANIX_OBJECTS_SECRET}
    deployNodeAgent: true
    nodeAgent:
      podVolumePath: /var/lib/kubelet/pods
      tolerations:
        - operator: Exists
EOF

# Patch helm release with overrides
kubectl --kubeconfig=${CLUSTER_NAME}.conf -n ${NKP_WORKSPACE_NAMESPACE} patch appdeployment velero --type="merge" --patch-file=/dev/stdin <<EOF
spec:
  configOverrides:
    name: velero-overrides
EOF

# Check for upgrade success or failure 
kubectl --kubeconfig=${CLUSTER_NAME}.conf get hr -n ${NKP_WORKSPACE_NAMESPACE} velero

# Force reconciliation
# kubectl --kubeconfig=${CLUSTER_NAME}.conf -n kommander   annotate helmrelease velero reconcile.fluxcd.io/requestedAt=$(date +%s) --overwrite