#!/usr/bin/env bash

set -ex
set -o pipefail

helm repo add ntnx-charts https://nutanix.github.io/helm-releases
helm repo update ntnx-charts
helm pull ntnx-charts/nai-core --version=$NAI_CORE_VERSION --untar=true

#NAI-core
helm upgrade --install nai-core ntnx-charts/nai-core --version=$NAI_CORE_VERSION -n nai-system --create-namespace --wait \
--set imagePullSecret.credentials.username=$DOCKER_USERNAME \
--set imagePullSecret.credentials.email=$DOCKER_EMAIL \
--set imagePullSecret.credentials.password=$DOCKER_PASSWORD \
--set naiApi.naiApiImage.tag=v1.0.0-rc2 \
--insecure-skip-tls-verify \
-f ./nai-core/$ENVIRONMENT-values.yaml