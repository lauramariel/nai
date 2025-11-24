export STORAGE_CLASS="nai-nfs-storage"
export PVC_NAME="my-pvc"
export POD_NAME="test-pod"

echo "Creating PVC $PVC_NAME..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC_NAME
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: $STORAGE_CLASS  # Replace this with the name of your storage class
EOF

echo "Waiting for PVC to be bound..."
kubectl wait --for=jsonpath='{.status.phase}=Bound' pvc/$PVC_NAME --timeout=60s || error_exit "PVC did not bind"
echo "PVC is bound."

echo "Deploying test pod ($POD_NAME) to write data..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  containers:
  - name: test-container
    image: busybox:1.36
    command: ["sh", "-c", "echo 'hello' > /mnt/data/test.txt && sleep 3600"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /mnt/data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: $PVC_NAME
  restartPolicy: Never
EOF