source ~/.env

INGRESS_HOST=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
NAI_UI_ENDPOINT="https://${INGRESS_HOST//./-}.sslip.nutanixdemo.com"
echo "Creating secret iep-cert for certificate"
# Create secret for certificates

# get certs
mkdir -p $HOME/certs
wget -O $HOME/certs/fullchain1.pem http://10.55.251.38/workshop_staging/tradeshows/configuration/certificates/sslip.nutanixdemo.com/fullchain1.pem 
wget -O $HOME/certs/privkey1.pem http://10.55.251.38/workshop_staging/tradeshows/configuration/certificates/sslip.nutanixdemo.com/privkey1.pem

CERT_PATH="$HOME/certs/fullchain1.pem"
KEY_PATH="$HOME/certs/privkey1.pem"
CERT_NAME="nai-cert"
kubectl create secret tls -n istio-system $CERT_NAME --cert=$CERT_PATH --key=$KEY_PATH

kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-nodeselector":"enabled"},"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}}}'
kubectl patch configmap config-features -n knative-serving --patch '{"data":{"kubernetes.podspec-tolerations":"enabled"}}'
kubectl patch configmap config-autoscaler -n knative-serving --patch '{"data":{"enable-scale-to-zero":"false"},"metadata":{"annotations":{"kustomize.toolkit.fluxcd.io/reconcile":"disabled"}}}'

kubectl patch gateways.networking.istio.io knative-ingress-gateway -n knative-serving --type merge --patch-file=/dev/stdin <<EOF
spec:
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: true
  - hosts:
    - '*'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: ${CERT_NAME}
EOF

echo "NAI_UI_ENDPOINT=$NAI_UI_ENDPOINT"