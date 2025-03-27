# if you need to update nai-iep-secret for puling new images from DockerHub (e.g. the nai-model-processor image that's used the first time you download a model)

#!/bin/bash

NAMESPACE="nai-admin"
SECRET_NAME="nai-iep-secret"
REGISTRY_URL="https://index.docker.io/v1/"
NEW_USERNAME=""
NEW_PASSWORD=""
EMAIL=""

# Generate a new .dockerconfigjson payload
DOCKER_CONFIG_JSON=$(echo -n "{\"auths\":{\"$REGISTRY_URL\":{\"username\":\"$NEW_USERNAME\",\"password\":\"$NEW_PASSWORD\",\"email\":\"$EMAIL\"}}}" | base64 -w0)

# Check if the secret exists
kubectl get secret $SECRET_NAME -n $NAMESPACE > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Updating existing secret: $SECRET_NAME"
    kubectl patch secret $SECRET_NAME -n $NAMESPACE --type='json' \
      -p="[{'op':'replace','path':'/data/.dockerconfigjson','value':'$DOCKER_CONFIG_JSON'}]"
else
    echo "Secret name $SECRET_NAME not found."
    exit 1
fi

# Confirm the update
kubectl get secret $SECRET_NAME -n $NAMESPACE -o yaml
