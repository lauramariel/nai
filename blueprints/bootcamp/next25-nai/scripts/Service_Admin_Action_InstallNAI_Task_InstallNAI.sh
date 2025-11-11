source ~/.env

# Make sure KServe is running
echo "Checking for Kserve"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve; do sleep 2; done

# Pull chart from private registry
export IMAGE_REGISTRY_URL="registry.nutanixdemo.com"
helm pull oci://$IMAGE_REGISTRY_URL/nai/nai-core --version v2.2.0 --untar=true

# Skip the image tag checks for private registry
PATCH_DATA=$(cat <<EOF
{"data":{"registries-skipping-tag-resolving":"$IMAGE_REGISTRY_URL"}}
EOF
)
kubectl patch configmap config-deployment -n knative-serving --type merge -p "$PATCH_DATA"

# Install nai-core from private registry
helm upgrade --install nai-core ./nai-core --version=v2.2.0 -n nai-system --create-namespace --wait \
--set naiApi.storageClassName=nutanix-files \
--set defaultStorageClassName=nutanix-volume \
--insecure-skip-tls-verify \
-f ./nai-core/values.yaml