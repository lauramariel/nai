# K8s default

## Drain all GPU nodes
```
kubectl get node -l nvidia.com/gpu.present=true -o name | cut -d/ -f2 | xargs -I {} sh -c "kubectl drain {} --delete-emptydir-data --ignore-daemonsets --disable-eviction && kubectl uncordon {}"
```

## Drain all CPU nodes
```
kubectl get node --selector='nvidia.com/gpu.present!=true,!node-role.kubernetes.io/control-plane' -o name | cut -d/ -f2 | xargs -I {} sh -c "kubectl drain {} --delete-emptydir-data --ignore-daemonsets --disable-eviction && kubectl uncordon {}"
```

## See what's running on a specific node in all namespaces
kubectl get pods -o wide --field-selector spec.nodeName=$NODE_NAME -A

## See what pods are using GPU
```
kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{.metadata.namespace} {.metadata.name} {.spec.containers[*].resources.requests.nvidia\.com/gpu}{"\n"}{end}' | cut -f2- -d' ' | grep ' [0-9]'
```

## Get resources requested by all deployments in given namespace
```
export NS="nai-admin"
for i in `kubectl  get deploy --no-headers -n $NS | awk '{print $1}'`; do echo $i; kubectl describe deploy $i -n $NS | egrep "Limits:|Requests:" -A3; done
```

## List all images used by each container
```
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |\
sort
```

# krew

## Search and install krew plugins
```
krew search
```

## Install plugins
```
krew install images
krew install browse-pvc
```

## Get image used by pods
```
kubectl images
```

## Browse pvc contents

This spins up and executes a temporary pod that attaches to the PVC
```
kubectl browse-pvc $PVC_NAME
```

### Example
```
[nutanix@dm3-poc139-jumphost ~]$ k browse-pvc nai-25913f19-f1f8-42e0-ab08-90-pvc-claim -n nai-admin
✓ Attached to browse-nai-25913f19-f1f8-42e0-ab08-90-pvc-claim-pnh8g
/mnt # ls
model-files
```

## kubens

### Switch namespace
```
kubens $NS
```
