# Uploading legacy charts to Harbor private registry

1. Download chart

    ```
    export NAI_CORE_VERSION="v2.4.0"
    export TOKEN="" # private access token that has access and is authorized to the repo (https://github.com/settings/tokens)
    wget --header="Authorization: token $TOKEN" https://github.com/nutanix-core/nai-helm-charts/archive/refs/tags/$NAI_CORE_VERSION.tar.gz
    ```

    Or just download it from the UI.

2. Untar package locally
    ```
    tar -xvzf $NAI_CORE_VERSION.tar.gz
    ```

3. cd to the charts directory
    ```
    cd nai-helm-charts-$NAI_CORE_VERSION/charts
    ```

4. Package it up
    ```
    helm package --version $NAI_CORE_VERSION ./nai-core/
    ```

5. Push it to Harbor
    ```
    docker login $HARBOR_URL -u admin
    helm push nai-core-$NAI_CORE_VERSION.tgz oci://$HARBOR_URL/nai
    ```

6. Test the pull
    ```
    helm pull oci://$HARBOR_URL/nai/nai-core --version $NAI_CORE_VERSION
    ```