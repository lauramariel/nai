# Example of how to use custom registry when installing NAI helm chart

## Step 1. Push images to custom registry

### Run from laptop
```
# Download artifactory chart locally

export ARTIFACTORY_USERNAME=""
export ARTIFACTORY_PASSWORD=""
export NAI_CORE_VERSION=""
export JUMPHOST=""

# pull chart locally
export NAI_CORE_VERSION="0.1.0+build.445"
helm repo add ntnx-canaveral-charts https://artifactory.dyn.ntnxdpro.com:443/artifactory/canaveral-helm/ --username $ARTIFACTORY_USERNAME --password $ARTIFACTORY_PASSWORD --pass-credentials --insecure-skip-tls-verify
helm repo update ntnx-canaveral-charts
helm pull ntnx-canaveral-charts/nai-core --version=$NAI_CORE_VERSION --insecure-skip-tls-verify

# copy chart to jumphost
scp nai-core-$NAI_CORE_VERSION.tgz nutanix@$JUMPHOST:~/

# pull the required images
docker login artifactory-edge-01.corp.p10y.ntnxdpro.com
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-iep-operator:latest
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-model-processor:latest
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-inference-ui:latest
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-api:latest
docker pull artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-tgi:2.3.1-825f39d

# tag
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-inference-ui registry.nutanixdemo.com/nai/nai-inference-ui:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-model-processor registry.nutanixdemo.com/nai/nai-model-processor:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-iep-operator registry.nutanixdemo.com/nai/nai-iep-operator:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-api registry.nutanixdemo.com/nai/nai-api:latest
docker tag artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-tgi:2.3.1-825f39d registry.nutanixdemo.com/nai/nai-tgi:2.3.1-825f39d

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
