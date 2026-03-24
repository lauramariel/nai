source ~/.env

export KSERVE_VERSION=v0.14.0

# Wait for istio and knative to be up
echo "Checking for Istio"
until kubectl wait --for condition=ready pods -l app=istio-ingressgateway -n istio-system; do sleep 2; done
echo "Checking for Knative"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=knative-serving -n knative-serving; do sleep 2; done

helm upgrade --install kserve-crd oci://ghcr.io/kserve/charts/kserve-crd --version=$KSERVE_VERSION -n kserve --create-namespace --wait

helm upgrade --install kserve oci://ghcr.io/kserve/charts/kserve --version=$KSERVE_VERSION -n kserve --wait \
--set kserve.modelmesh.enabled=false --set kserve.controller.image=docker.io/nutanix/nai-kserve-controller \
--set kserve.controller.tag=$KSERVE_VERSION