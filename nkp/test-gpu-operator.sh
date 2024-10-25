kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
  - name: cuda-vector-add
    image: k8s.gcr.io/cuda-vector-add:v0.1
    resources:
      limits:
        nvidia.com/gpu: 1
EOF