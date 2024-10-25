
# Installing NAI on NKP

## Pre-requisites
- Linux jumphost with nkp-cli installed
  - https://github.com/nutanixdev/nkp-quickstart
- Nutanix Files server (PE-deployed)
- TLS certificate and key

## Prepare environment
1. Update sample.env with your environment variables and source the file

## Create NKP cluster
1. Upload Ubuntu image to Prism Central for NKP cluster nodes or create it via NKP with

    ```
    nkp create image nutanix ubuntu-22.04 \
        --endpoint ${NUTANIX_ENDPOINT} --cluster ${NUTANIX_PRISM_ELEMENT_CLUSTER_NAME} \
        --subnet ${NUTANIX_SUBNET_NAME} --insecure
    ```

1. Set environment variable NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME to the name of this image
1. Create NKP cluster

    ```
    sh create-nkp-cluster.sh
    ```
1. License NKP cluster
1. Add GPU node pool
    ```
    sh create-nkp-gpu-nodepool.sh
    ```
1. Install GPU operator from NKP dashboard 
1. Test operator

    ```
    sh test-gpu-operator.sh
    ```

## Install NAI
1. Install pre-requisites
   
   ```
   sh nai-deploy.sh
   ```

1. Install NAI

    ```
    sh nai-deploy.sh
    ```
1. Post-install steps
   ```
   sh nai-post.sh
   ```