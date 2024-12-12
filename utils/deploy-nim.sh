# Create test pod for NIM

STORAGE_CLASS="nai-nfs-storage"
NGC_CLI_API_KEY=""

# Create secret with NGC API key
kubectl create secret generic ngc-secret \
    --from-literal=NGC_API_KEY="$NGC_CLI_API_KEY" \
    # --type=kubernetes.io/dockerconfigjson

# Create PVC from storage class to request storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: $STORAGE_CLASS  # Replace this with the name of your storage class
EOF

# Apply configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: llama-3-1-8b-instruct
spec:
  containers:
  - name: llama-container
    image: nvcr.io/nim/meta/llama-3.1-8b-instruct@sha256:e990eb6915c0917509318942bb5440291b0a2d498bdd6f2ebc1b8dfc4580f2d4
    volumeMounts:
    - mountPath: /mnt/models
      name: my-storage
    resources:
      requests:
        memory: "16Gi"
        nvidia.com/gpu: 1
      limits:
        memory: "16Gi"
        nvidia.com/gpu: 1
    env:
    - name: NGC_API_KEY
      valueFrom:
        secretKeyRef:
          name: ngc-secret
          key: NGC_API_KEY
    ports:
    - containerPort: 8000
    securityContext:
      runAsUser: 1000  # Replace with your specific UID if different
    # Configure shared memory size for better performance if necessary
  imagePullSecrets:
  - name: ngc-secret
  volumes:
    - name: my-storage
      persistentVolumeClaim:
        claimName: my-pvc
EOF

# Ubuntu pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-pod
spec:
  containers:
  - name: ubuntu-container
    image: ubuntu:latest
    command: ["/bin/bash", "-c", "sleep infinity"]
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    volumeMounts:
    - mountPath: /data
      name: persistent-storage
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: my-pvc
EOF