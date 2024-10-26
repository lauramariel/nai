(WIP)
## Downloading a model
When you download a model, in the nai-admin namespace, a kubernetes job is created that kicks off a temporary nai-model-processor container in the same namespace. This container has several environment variables set, including the model image to download (e.g. nvcr.io/nim/meta/llama-3.1-8b-instruct:1.2.2) and the API key via Kubernetes secret. This container creates the PV/PVC and mounts the volume.

```
[nutanix@localhost ~]$ k get pv -n nai-admin | grep nai-admin
pvc-3505d98b-415e-468e-ac23-9fcaf8167e9b   47Gi       RWX            Delete           Bound    nai-admin/nai-208c647e-d873-49e1-86cc-6e-pvc-claim                                     nai-nfs-storage   <unset>                          3m9s
[nutanix@localhost ~]$ k get pvc -n nai-admin
NAME                                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      VOLUMEATTRIBUTESCLASS   AGE
nai-208c647e-d873-49e1-86cc-6e-pvc-claim   Bound    pvc-3505d98b-415e-468e-ac23-9fcaf8167e9b   47Gi       RWX            nai-nfs-storage   <unset>                 3m25s
```

### NIM model download
When you download a NIM model, the share is created on the file server (assuming the StorageClass configuration is set to dynamic provisioning) but the model isn’t actually downloaded yet until the endpoint is created.

![](./images/file-share-after-nim-download.png)

### Troubleshooting
If the volume fails to mount because of DNS resolution errors to the file server, double check the networking configuration and ensure that the Kubernetes nodes are on a network that is set to search the domain of the file server.

E.g. the nai-model-processor container fails to start with the following error:

```
MountVolume.SetUp failed for volume "pvc-96f09e5d-0a40-487a-8b02-ca1597feb404" : rpc error: code = Internal desc = rpc error: code = Internal desc = mount failed: exit status 32
Mounting command: mount
Mounting arguments: -t nfs nai-fs.ntnxlab.local:/pvc-96f09e5d-0a40-487a-8b02-ca1597feb404 /var/lib/kubelet/pods/efb52398-ecc9-478b-9f86-9a0303e40bf4/volumes/kubernetes.io~csi/pvc-96f09e5d-0a40-487a-8b02-ca1597feb404/mount
Output: mount.nfs: Failed to resolve server nai-fs.ntnxlab.local: Name or service not known
```

Check the network settings to ensure the search domain is set. For example, on an AHV network, make sure the domain settings have the domain in the “Domain Search” field. 

![](./images/domain-settings-ahv-subnet.png)
