tmpdir = $(shell mktemp -d)

if [ -z "$NAI_CORE_VERSION" ] || [ -z "$ARTIFACTORY_USERNAME" ] || [ -z "$ARTIFACTORY_PASSWORD" ]; then \
	echo "Error: NAI_CORE_VERSION, ARTIFACTORY_USERNAME and ARTIFACTORY_PASSWORD must be set"; \
	exit 1;
fi

echo "Temporary directory created: $tmpdir"
helm repo add ntnx-canaveral-charts https://artifactory.dyn.ntnxdpro.com:443/artifactory/canaveral-helm/ --username $ARTIFACTORY_USERNAME --password $ARTIFACTORY_PASSWORD --pass-credentials --insecure-skip-tls-verify
helm repo update ntnx-canaveral-charts
helm pull ntnx-canaveral-charts/nai-core --version=$NAI_CORE_VERSION --insecure-skip-tls-verify --untar=true --untardir=$tmpdir

helm install nai-core ntnx-canaveral-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
	--set imagePullSecret.credentials.registry=artifactory-edge-01.corp.p10y.ntnxdpro.com \
	--set naiIepOperator.iepOperatorImage.image=artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-iep-operator \
	--set naiIepOperator.modelProcessorImage.image=artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-model-processor \
	--set naiInferenceUi.naiUiImage.image=artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-inference-ui \
	--set naiApi.naiApiImage.image=artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core/nai-api \
	--set imagePullSecret.credentials.username=$ARTIFACTORY_USERNAME \
	--set imagePullSecret.credentials.email=$ARTIFACTORY_USERNAME \
	--set imagePullSecret.credentials.password=$ARTIFACTORY_PASSWORD \
	--insecure-skip-tls-verify \
	-f $tmpdir/nai-core/$ENVIRONMENT-values.yaml

rm -rf $tmpdir