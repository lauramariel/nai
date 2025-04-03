wget http://10.55.251.38/workshop_staging/tradeshows/software/langfuse/langfuse-values.yaml

# TODO: make sure ingress is up

export INSTANCE="langfuse"
export INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[].ip}" && echo)
export SSLIP_HOSTNAME="${INSTANCE}-${INGRESS_IP//./-}.sslip.nutanixdemo.com"

kubectl create namespace ${INSTANCE} --dry-run=client -o yaml | kubectl apply -f -

# use the existing certificate
kubectl get secret -n istio-system nai-cert -o yaml | sed "s/namespace: istio-system/namespace: ${INSTANCE}/g" | kubectl apply -f -
kubectl get secret nai-cert -n ${INSTANCE}

# install langfuse
helm repo add langfuse https://langfuse.github.io/langfuse-k8s
helm repo update

yq -e -i ".langfuse.ingress.hosts[0].host = strenv(SSLIP_HOSTNAME)" langfuse-values.yaml
yq -e -i ".langfuse.ingress.tls.hosts[0] = strenv(SSLIP_HOSTNAME)" langfuse-values.yaml

time helm upgrade --install langfuse langfuse/langfuse -f langfuse-values.yaml \
  --namespace ${INSTANCE} \
  --wait