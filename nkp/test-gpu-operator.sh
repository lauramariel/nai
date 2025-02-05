#!/usr/bin/env bash

set -ex
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
  - name: cuda-vector-add
    env:
    - name: NVIDIA_IMEX_CHANNELS
      value: "0"
    image: k8s.gcr.io/cuda-vector-add:v0.1
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

sleep 10
kubectl logs cuda-vector-add