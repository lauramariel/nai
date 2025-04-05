# Install ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.allowSnippetAnnotations=true \
  --set controller.ingressClassResource.default=true \
  --set force-ssl-redirect=true \
  --version=4.8.3 \
  --wait
kubectl --namespace ingress-nginx get services -o wide ingress-nginx-controller
