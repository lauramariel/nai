helm repo add milvus https://zilliztech.github.io/milvus-helm/
helm repo update

# Install
helm upgrade --cleanup-on-fail \
  --install milvus-vectordb milvus/milvus \
  --namespace milvus \
  --create-namespace \
  --values milvus-values.yaml
