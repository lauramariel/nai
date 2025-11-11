# Installing Milvus in 5 namespaces for 5 users

helm repo add milvus https://zilliztech.github.io/milvus-helm/
helm repo update

cd ~
export MILVUS_VALUES_FILE="milvus-values.yaml"
export MILVUS_INGRESS_FILE="milvus-ingress.yaml"
export MILVUS_ATTU_INGRESS_FILE="milvus-attu-ingress.yaml"

# Create Milvus config templates
cat <<EOF > $MILVUS_VALUES_FILE
#ATTU Frontend
attu:
  enabled: true
  name: attu
  service:
    type: ClusterIP
    port: 80

# Milvus Cluster settings
cluster:
  enabled: false

etcd:
  replicaCount: 1

pulsar:
  enabled: false

service:
  type: ClusterIP
  ports:
  - port: 80
    protocol: TCP
    targetPort: 19530

# Disable MinIO and configuring External S3
minio:
  enabled: false

externalS3:
  enabled: true
  host: "" # Nutanix Objects Instance IP
  port: 80
  accessKey: "" # Access Key
  secretKey: "" # Secret Key
  useSSL: false
  bucketName: "docs" # Bucket Name
  rootPath: ""
  region: us-east-1
  useVirtualHost: false
EOF

cat <<EOF > $MILVUS_INGRESS_FILE
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: milvus-vectordb
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - hostname # the FQDN
    secretName: nai-cert
  rules:
    - host: hostname
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: milvus-vectordb
                port:
                  number: 19530
EOF

cat <<EOF > $MILVUS_ATTU_INGRESS_FILE
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: milvus-vectordb-attu
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: 2048m
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - hostname # the FQDN
    secretName: nai-cert
  rules:
    - host: hostname
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: milvus-vectordb-attu
                port:
                  number: 80
EOF

for i in {1..5}
do
    export INSTANCE="milvus-adminuser0$i"

    kubectl create namespace ${INSTANCE} --dry-run=client -o yaml | kubectl apply -f -

    # use the existing certificate
    kubectl get secret -n istio-system nai-cert -o yaml | sed "s/namespace: istio-system/namespace: ${INSTANCE}/g" | kubectl apply -f -
    kubectl get secret nai-cert -n ${INSTANCE}

    export S3_HOST="@@{NUS_OBJ_INSTANCE_IP_ADDRESS}@@"
    export S3_ACCESS_KEY="@@{SHARED_OBJECTS_ACCESS_KEY}@@"
    export S3_SECRET_KEY="@@{SHARED_OBJECTS_SECRET_KEY}@@"
    export S3_BUCKET_NAME="adminuser0$i"

    # Update user-specific values
    yq -i -e '.externalS3.host = strenv(S3_HOST)' $MILVUS_VALUES_FILE
    yq -i -e '.externalS3.accessKey = strenv(S3_ACCESS_KEY)' $MILVUS_VALUES_FILE
    yq -i -e '.externalS3.secretKey = strenv(S3_SECRET_KEY)' $MILVUS_VALUES_FILE
    yq -i -e '.externalS3.bucketName = strenv(S3_BUCKET_NAME)' $MILVUS_VALUES_FILE

    # Install
    helm upgrade --cleanup-on-fail \
        --install milvus-vectordb milvus/milvus --version 4.2.44 \
        --set image.tag="2.5.8" \
        --namespace ${INSTANCE} \
        --create-namespace \
        --wait \
        --values milvus-values.yaml

    # Configure ingress
    export INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[].ip}" && echo)
    export DB_HOSTNAME="${INSTANCE}-${INGRESS_IP//./-}.sslip.nutanixdemo.com"
    export ATTU_HOSTNAME="${INSTANCE}-attu-${INGRESS_IP//./-}.sslip.nutanixdemo.com"
    yq -i -e ".spec.rules[0].host = strenv(DB_HOSTNAME)" $MILVUS_INGRESS_FILE
    yq -i -e ".spec.tls[0].hosts[0] = strenv(DB_HOSTNAME)" $MILVUS_INGRESS_FILE
    yq -i -e ".spec.rules[0].host = strenv(ATTU_HOSTNAME)" $MILVUS_ATTU_INGRESS_FILE
    yq -i -e ".spec.tls[0].hosts[0] = strenv(ATTU_HOSTNAME)" $MILVUS_ATTU_INGRESS_FILE


    kubectl apply -f $MILVUS_INGRESS_FILE -n ${INSTANCE}
    kubectl apply -f $MILVUS_ATTU_INGRESS_FILE -n ${INSTANCE}
    
 done