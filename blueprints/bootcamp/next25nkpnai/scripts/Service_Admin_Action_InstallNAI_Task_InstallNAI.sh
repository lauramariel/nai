source ~/.env

helm repo add ntnx-charts https://nutanix.github.io/helm-releases
helm repo update ntnx-charts
helm pull ntnx-charts/nai-core --version=$NAI_CORE_VERSION --untar=true

# Make sure KServe is running
echo "Checking for Kserve"
until kubectl wait --for condition=ready pods -l app.kubernetes.io/name=kserve-controller-manager -n kserve; do sleep 2; done

#NAI-core
helm upgrade --install nai-core ntnx-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
--set imagePullSecret.credentials.username=$DOCKER_USERNAME \
--set imagePullSecret.credentials.email=$DOCKER_EMAIL \
--set imagePullSecret.credentials.password=$DOCKER_PASSWORD \
--set naiApi.storageClassName=nutanix-files \
--set defaultStorageClassName=nutanix-volume \
--insecure-skip-tls-verify \
-f ./nai-core/values.yaml