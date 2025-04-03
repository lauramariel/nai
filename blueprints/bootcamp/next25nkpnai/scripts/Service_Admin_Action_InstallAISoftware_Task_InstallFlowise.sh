# TODO: make sure ingress is up

# Make sure the istio-system namespace is up
until kubectl get namespace istio-system &>/dev/null; do echo "Waiting for namespace istio-system";  sleep 2; done

# INSTANCE=flowise-user#
for i in {1..5}
do
  export INSTANCE="flowise-user$i"
  export INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[].ip}" && echo)
  export SSLIP_HOSTNAME="${INSTANCE}-${INGRESS_IP//./-}.sslip.nutanixdemo.com"

  kubectl create namespace ${INSTANCE} --dry-run=client -o yaml | kubectl apply -f -

  # use the existing certificate
  kubectl get secret -n istio-system nai-cert -o yaml | sed "s/namespace: istio-system/namespace: ${INSTANCE}/g" | kubectl apply -f -
  kubectl get secret nai-cert -n ${INSTANCE}

  # install flowise
  helm repo add cowboysysop https://cowboysysop.github.io/charts/
  helm repo update cowboysysop

  time helm upgrade --install flowise cowboysysop/flowise --version 3.11.3 \
    --namespace ${INSTANCE} \
    --set image.tag="2.2.7" \
    --set ingress.enabled=true \
    --set ingress.ingressClassName="nginx" \
    --set ingress.hosts[0].host="${SSLIP_HOSTNAME}" \
    --set ingress.hosts[0].paths[0]="/" \
    --set ingress.tls[0].secretName="iep-cert" \
    --set ingress.tls[0].hosts[0]="${SSLIP_HOSTNAME}" \
    --wait
 done