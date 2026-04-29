

# Authenticate to your registry
#helm registry login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD https://$IMAGE_REGISTRY_URL

# Push each chart to the registry
helm push gateway-crds-helm-v1.6.3.tgz oci://$IMAGE_REGISTRY_URL
helm push gateway-helm-v1.6.3.tgz oci://$IMAGE_REGISTRY_URL
helm push kserve-crd-v0.15.0.tgz oci://$IMAGE_REGISTRY_URL
helm push kserve-v0.15.0.tgz oci://$IMAGE_REGISTRY_URL
helm push nai-core-2.6.0.tgz oci://$IMAGE_REGISTRY_URL
helm push nai-operators-2.6.0.tgz oci://$IMAGE_REGISTRY_URL
helm push opentelemetry-operator-0.102.0.tgz oci://$IMAGE_REGISTRY_URL
