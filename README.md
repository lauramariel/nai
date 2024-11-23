
# Installing NAI on NKP

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
1. Copy your ssh keys to the jumphost (or create new ones)
1. Install `yq` (needed until NKP 2.13 when GPU switch is supported (NCN-102486))
    ```
    sudo su
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq
    ```

1. Update sample.env with your environment variables and source the file

## Create NKP cluster
1. Upload NKP Ubuntu image to Prism Central or create it via NKP Image Builder with

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
   sh nai-prepare.sh
   ```

1. Install NAI

    ```
    sh nai-deploy.sh
    ```
1. Post-install steps
   ```
   sh nai-post.sh
   ```

## Appendix

### Setting up DNS and certificates before running nai-post.sh
1. Once NAI is running find the IP of the istio ingress gateway

```
k get svc istio-ingressgateway -n istio-system
```

1. Set up a DNS record (e.g. in Route 53) pointing an FQDN to this IP
1. Create a certificate with this DNS record (more later)
1. Set cert and key env variables in .env
