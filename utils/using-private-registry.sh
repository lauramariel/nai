# assumes you're logged into both registries
# docker login $OLD_REPO -u username
# docker login $NEW_REPO -u username

export OLD_REPO=artifactory-edge-01.corp.p10y.ntnxdpro.com/canaveral-legacy-docker/nutanix-core
export NEW_REPO=registry.nutanixdemo.com/nai
export NEW_REPO=dm3-registry.nutanixdemo.com/nai

docker pull $OLD_REPO/nai-api:v2.4.0-rc1
docker pull $OLD_REPO/nai-iep-operator:v2.4.0-rc1
docker pull $OLD_REPO/nai-inference-ui:v2.4.0-rc1
docker pull $OLD_REPO/nai-kserve-custom-model-server:v2.4.0-rc1
docker pull $OLD_REPO/nai-kserve-huggingfaceserver:v0.15.2
docker pull $OLD_REPO/nai-kserve-huggingfaceserver:v0.15.2-gpu
docker pull $OLD_REPO/nai-tgi:3.3.4-b2485c9
docker pull $OLD_REPO/nai-model-processor:v2.4.0-rc1

docker tag $OLD_REPO/nai-api:v2.4.0-rc1 $NEW_REPO/nai-api:v2.4.0-rc1
docker tag $OLD_REPO/nai-iep-operator:v2.4.0-rc1 $NEW_REPO/nai-iep-operator:v2.4.0-rc1
docker tag $OLD_REPO/nai-inference-ui:v2.4.0-rc1 $NEW_REPO/nai-inference-ui:v2.4.0-rc1
docker tag $OLD_REPO/nai-kserve-custom-model-server:v2.4.0-rc1 $NEW_REPO/nai-kserve-custom-model-server:v2.4.0-rc1
docker tag $OLD_REPO/nai-kserve-huggingfaceserver:v0.15.2 $NEW_REPO/nai-kserve-huggingfaceserver:v0.15.2
docker tag $OLD_REPO/nai-kserve-huggingfaceserver:v0.15.2-gpu $NEW_REPO/nai-kserve-huggingfaceserver:v0.15.2-gpu
docker tag $OLD_REPO/nai-tgi:3.3.4-b2485c9 $NEW_REPO/nai-tgi:3.3.4-b2485c9
docker tag $OLD_REPO/nai-model-processor:v2.4.0-rc1 $NEW_REPO/nai-model-processor:v2.4.0-rc1

docker push $NEW_REPO/nai-api:v2.4.0-rc1
docker push $NEW_REPO/nai-iep-operator:v2.4.0-rc1
docker push $NEW_REPO/nai-inference-ui:v2.4.0-rc1
docker push $NEW_REPO/nai-kserve-custom-model-server:v2.4.0-rc1
docker push $NEW_REPO/nai-kserve-huggingfaceserver:v0.15.2
docker push $NEW_REPO/nai-kserve-huggingfaceserver:v0.15.2-gpu
docker push $NEW_REPO/nai-tgi:3.3.4-b2485c9
docker push $NEW_REPO/nai-model-processor:v2.4.0-rc1

