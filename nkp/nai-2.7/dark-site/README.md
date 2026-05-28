Ideally done from a VM with at least 100GB of free space.

1. Add contents of sample.env to your .env file and update to match your environment
    ```
    cat sample.env >> .env
    vi .env
    ```

2. Source .env file
    ```
    source .env
    ```

3. Download airgapped bundle and charts from portal
   1. NAI 2.7.0 Airgap Bundle
   2. NAI 2.7.0 Helm Charts

    e.g.
    ```
    wget -O nai-helm-charts-2.7.0.tar "$PORTAL_LINK"
    wget -O nai-v2.7.0.tar "$PORTAL_LINK"
    ```

    Replace `$PORTAL_LINK` with the short-lived URL obtained from the portal.

4. Authenticate to your registry

    ```
    helm registry login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD ${IMAGE_REGISTRY_URL%%/*}
    ```

    Note: `${IMAGE_REGISTRY_URL%%/*}` ensures that only the domain is passed.
    e.g. registry.example.com/bootcamps becomes registry.example.com

5. Untar the helm chart directory

    ```
    mkdir nai-helm-charts-2.7.0 && tar -xvf nai-helm-charts-2.7.0.tar -C nai-helm-charts-2.7.0
    ```

6. Put chart names in charts.txt

    ```
    ls -l nai-helm-charts-2.7.0 | awk '{print $9}' | awk 'NF' > charts.txt
    ```

7. Edit `00-push-charts.sh` with the path to the charts
8. Push charts to registry

    ```
    bash 00-push-charts.sh
    ```

9.  Push images to registry with `00-push-images.sh`

    ```
    bash 00-push-images.sh registry.nutanixdemo.com/bootcamps nutanix nai-v2.7.0.tar
    ```
