# Uploading legacy charts to Harbor private registry

## Tested with v2.2.0 chart

1. Set HARBOR_URL to your private registry (domain name only)

    ```
    export HARBOR_URL='myregistry.com'
    ```

1. Download chart

    ```
    export NAI_CORE_VERSION="v2.2.0"
    export TOKEN="" # private access token that has access and is authorized to the repo (https://github.com/settings/tokens)
    wget --header="Authorization: token $TOKEN" https://github.com/nutanix-core/nai-helm-charts/archive/refs/tags/$NAI_CORE_VERSION.tar.gz
    ```

    Or just download it from the UI.

1. Untar package locally
    ```
    tar -xvzf $NAI_CORE_VERSION.tar.gz
    ```

1. cd to the charts directory
    ```
    cd nai-helm-charts-$NAI_CORE_VERSION/charts
    ```

1. Update values.yaml

   * Change URL and remove login for imagePullSecret (assuming registry doesn't require auth, if it does, remove the delete commands and modify accordingly)

    ```
    yq e -i ".imagePullSecret.credentials.registry = \"$HARBOR_URL\" | del(.imagePullSecret.credentials.username) | del(.imagePullSecret.credentials.password) | del(.imagePullSecret.credentials.email)" nai-core/values.yaml
    ```

   * Update image locations (sed command on Mac requires the extra `''`, if not on Mac, modify accordingly)

    ```
    sed -i '' "s|docker.io/nutanix|$HARBOR_URL/nai|g" nai-core/values.yaml
    ```
    * Update tags from latest to the required version
    ```
    sed -i '' "s|tag: latest|tag: $NAI_CORE_VERSION|g" nai-core/values.yaml
    ```

1. Package it up
    ```
    helm package --version $NAI_CORE_VERSION ./nai-core/
    ```

1. Push it to Harbor
    ```
    docker login $HARBOR_URL -u admin
    helm push nai-core-$NAI_CORE_VERSION.tgz oci://$HARBOR_URL/nai
    ```

1. Test the pull
    ```
    helm pull oci://$HARBOR_URL/nai/nai-core --version $NAI_CORE_VERSION
    ```