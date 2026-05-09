# Configuring Velero

This script sets up the secret, configmap, and patches the Velero AppDeployment to write the default BackupStorageLocation to a Nutanix Objects cluster with a self-signed cert based on the instructions in the [NKP Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform-v2_17:top-velero-with-nutanix-prep-environment-t.html).


## Set up S3 bucket
First, set up the following:
* Nutanix Objects Bucket
* Access Key and Secret Key with access to that bucket (in my demo environment, I gave full access)

## Update env file to match your environment
```
vi velero.env
```

## Run script
```
bash configure-velero-with-objects.sh
```
