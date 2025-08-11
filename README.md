
# Installing NAI on NKP (Updated for NAI 2.4 on NKP 2.15)

## Pre-requisites
- Linux jumphost with nkp-cli installed
  - https://github.com/nutanixdev/nkp-quickstart
- Nutanix Files server (PE-deployed to support dynamic provisioning of shares)
- TLS certificate and key

## Optional - set jumphost hostname
```
sudo su
hostnamectl set-hostname <desired-hostname>
```

## Prepare environment
1. Copy your ssh keys to the jumphost (or create new ones). These are the keys that will enable access to the NKP nodes.
1. Update sample.env with your environment variables and source the file

```
source .env
```

## Create NKP cluster
1. Upload NKP Ubuntu image to Prism Central or create it via NKP Image Builder with

    ```
    nkp create image nutanix ubuntu-22.04 \
        --endpoint ${NUTANIX_ENDPOINT} --cluster ${NUTANIX_PRISM_ELEMENT_CLUSTER_NAME} \
        --subnet ${NUTANIX_SUBNET_NAME} --insecure
    ```

1. Update environment variable NKP_UBUNTU_IMAGE to the name of this image
1. cd to `nkp` directory
    ```
    cd nkp
    ```
1. Create NKP cluster

    ```
    sh nkp-create-cluster.sh
    ```
1. License NKP cluster
1. Add GPU node pool
    ```
    sh nkp-create-gpunodepool.sh
    ```
1. Install GPU operator from NKP dashboard

    If the Ubuntu image did not have drivers installed, add the following to the configuration:
    ```
    driver:
        enabled: true
    ```

1. Test operator

    ```
    sh test-gpu-operator.sh
    ```
## Install NAI - From NKP

### Versions
- NAI 2.4
- NKP 2.15

1. From nkp directory, cd to `nai-2.4`

    ```
    cd nai-2.4
    ```

1. Run nai_prepare.sh

    This will:
    - Install envoy gateway
    - Enable app catalog
    - Create secret for CSI Driver authentication
    - Create storage class

    ```
    bash nai-prepare.sh
    ```

1. Enable NAI from NKP catalog with the following config:

    ```
    imagePullSecret:
        # Name of the image pull secret
        name: nai-iep-secret
        # Image registry credentials
        credentials:
            registry: https://index.docker.io/v1/
            username: <username>
            password: <password>
            email: <email>
    storageClassName: nai-nfs-storage
    ```

    Be sure to replace username, password, and e-mail with the Docker Hub credentials you were provided.

1. Wait until all pods are running in nai-system namespace
    ```
    kubectl get pods -n nai-system
    ```

1. Update dashboard link with FQDN or IP

    ```
    bash nai-dashboard-link.sh 'https://<FQDN>'
    ```

1. Set up certificates. See the [appendix](https://github.com/lauramariel/nai/blob/main/README.md#appendix).

    ```
    bash nai-cert-setup.sh
    ```

## Install NAI - Manual method

Coming soon

## Appendix

### Setting up DNS and certificates for bringing your own cert
1. Once NAI is running find the IP of the ingress gateway

```
kubectl get gateway nai-ingress-gateway -n nai-system -o jsonpath='{.status.addresses[0].value}{"\n"}'
```

1. Set up a DNS record (e.g. in Route 53) pointing an FQDN to this IP
1. Create a certificate with this DNS record (with ZeroSSL or Lets Encrypt)
1. Copy the cert and key to the workstation where you are running the scripts and take note of the paths
