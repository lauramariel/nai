# Configuring Velero

This script sets up the secret, configmap, and patches the Velero AppDeployment to write the default BackupStorageLocation to a Nutanix Objects cluster with a self-signed cert based on the instructions in the [NKP Guide](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform-v2_17:top-velero-with-nutanix-prep-environment-t.html).

## Install velero cli

Follow official install guide based on the version in your cluster (e.g. https://velero.io/docs/v1.18/basic-install/)

To get version from NKP
```
kubectl get helmrelease velero -o yaml | yq .status.history[0].appVersion
```

## Set up S3 bucket
Set up the following:
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

## Creating a test backup
```
# Create a test namespace
kubectl create namespace velero-hello-world

# Deploy a simple Nginx instance
kubectl create deployment nginx --image=nginx -n velero-hello-world

# Create a "secret message" inside a ConfigMap to prove it restores metadata
kubectl create configmap hello-message --from-literal=greeting="Hello from the past!" -n velero-hello-world
```

Once the pod is running
```
kubectl get pods -n velero-hello-world
```

Create the backup
```
velero backup create hello-backup -n ${NKP_WORKSPACE_NAMESPACE} --include-namespaces velero-hello-world
```

View the backup
```
velero backup get -n ${NKP_WORKSPACE_NAMESPACE}
```

Example output
```
NAME                            STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
hello-backup                    Completed   0        0          2026-05-09 01:58:08 +0000 UTC   29d       ntnx-object-nkp    <none>
```
