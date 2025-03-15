# Example of how to use custom registry when installing NAI helm chart

## Step 1. Push images to custom registry

### Run from laptop
```
# Download artifactory chart locally

export ARTIFACTORY_USERNAME="<okta_email>"
export ARTIFACTORY_PASSWORD="<api_key>"
export NAI_CORE_VERSION=""
export JUMPHOST=""

# pull chart locally
export NAI_CORE_VERSION="2.2.0-release-branch+build.845"
helm repo add ntnx-canaveral-charts https://artifactory.dyn.ntnxdpro.com:443/artifactory/canaveral-helm/ --username $ARTIFACTORY_USERNAME --password $ARTIFACTORY_PASSWORD --pass-credentials --insecure-skip-tls-verify
helm repo update ntnx-canaveral-charts
helm pull ntnx-canaveral-charts/nai-core --version=$NAI_CORE_VERSION --insecure-skip-tls-verify

# copy chart to jumphost
scp nai-core-$NAI_CORE_VERSION.tgz nutanix@$JUMPHOST:~/

# pull the required images
docker login artifactory-edge-01.corp.p10y.ntnxdpro.com
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-iep-operator:1056
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-model-processor:1056
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-inference-ui:3143
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-api:8610
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-tgi

# tag
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-inference-ui:3143 registry.nutanixdemo.com/nai/nai-inference-ui:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-model-processor:1056 registry.nutanixdemo.com/nai/nai-model-processor:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-iep-operator:1056 registry.nutanixdemo.com/nai/nai-iep-operator:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-api:8610 registry.nutanixdemo.com/nai/nai-api:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-tgi registry.nutanixdemo.com/nai/nai-tgi:latest

# push to registry on HPOC network
docker login registry.nutanixdemo.com
docker push registry.nutanixdemo.com/nai/nai-inference-ui:latest
docker push registry.nutanixdemo.com/nai/nai-model-processor:latest
docker push registry.nutanixdemo.com/nai/nai-iep-operator:latest
docker push registry.nutanixdemo.com/nai/nai-api:latest
docker push registry.nutanixdemo.com/nai/nai-tgi:2.3.1-825f39d
```
## Step 2. Install from registry

### On jumphost connected to K8s cluster
```
# install

helm install nai-core nai-core-$NAI_CORE_VERSION.tgz --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
	--set naiIepOperator.iepOperatorImage.image=registry.nutanixdemo.com/nai/nai-iep-operator \
	--set naiIepOperator.modelProcessorImage.image=registry.nutanixdemo.com/nai/nai-model-processor \
	--set naiInferenceUi.naiUiImage.image=registry.nutanixdemo.com/nai/nai-inference-ui \
	--set naiApi.naiApiImage.image=registry.nutanixdemo.com/nai/nai-api \
  	--set naiApi.supportedTGIImage=registry.nutanixdemo.com/nai/nai-tgi:2.3.1-825f39d \
	--insecure-skip-tls-verify \
	-f ./nai-core/nkp-values.yaml
```

```
helm upgrade --install nutanix-ai nai-core-$NAI_CORE_VERSION.tgz --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
		--set naiIepOperator.iepOperatorImage.image=registry.nutanixdemo.com/nai/nai-iep-operator \
		--set naiIepOperator.modelProcessorImage.image=registry.nutanixdemo.com/nai/nai-model-processor \
		--set naiInferenceUi.naiUiImage.image=registry.nutanixdemo.com/nai/nai-inference-ui \
		--set naiApi.naiApiImage.image=registry.nutanixdemo.com/nai/nai-api \
		--set naiApi.supportedTGIImage=registry.nutanixdemo.com/nai/nai-tgi:2.3.1-825f39d \
        --set naiIepOperator.iepOperatorImage.tag=latest \
        --set naiIepOperator.modelProcessorImage.tag=latest \
        --set naiInferenceUi.naiUiImage.tag=latest \
        --set naiApi.naiApiImage.tag=latest
        --set naiApi.supportedKserveRuntimeImage=quay.io/saileshd1402/huggingfaceserver:master-3e842b8-gpu \
        --set naiApi.supportedKserveCPURuntimeImage=quay.io/saileshd1402/huggingfaceserver:master-3e842b8 \
        --insecure-skip-tls-verify
```
