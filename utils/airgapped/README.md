This script pulls container images defined in images.txt, tags them, then pushes to the destination registry.

Images should be in images.txt

Specify login-source if any of the image paths specified in images.txt require a login

Usage:
```
bash generate-migration-script.sh <destination_registry> [--pull] [--tag] [--push] [--dest-path] [[--login-source]]
```

Example usage
```
bash generate-migration-script.sh destination.example.com --dest-path images --login-source source.example.com
```

Sample output:
```
Generated migrate-images.sh
Options: pull=true, tag=true, push=true, dest-path=images, login-sources=source.example.com
```

Example generated script
```
#!/usr/bin/env bash
set -euo pipefail

docker login source.example.com
docker login destination.example.com

echo "Processing docker.io/library/nginx:1.25"
docker pull docker.io/library/nginx:1.25
docker tag docker.io/library/nginx:1.25 destination.example.com/images/library/nginx:1.25
docker push destination.example.com/images/library/nginx:1.25

echo "Processing quay.io/coreos/etcd:v3.5.12"
docker pull quay.io/coreos/etcd:v3.5.12
docker tag quay.io/coreos/etcd:v3.5.12 destination.example.com/images/coreos/etcd:v3.5.12
docker push destination.example.com/images/coreos/etcd:v3.5.12

echo "Processing source.example.com/team/app:2.1.0"
docker pull source.example.com/team/app:2.1.0
docker tag source.example.com/team/app:2.1.0 destination.example.com/images/team/app:2.1.0
docker push destination.example.com/images/team/app:2.1.0
```

You can use the --pull, --push, and --tag options if you want a script that just contains those actions e.g.

```
bash generate-migration-script.sh destination.example.com --dest-path images --tag
```

will produce a script that just contains

```
echo "Processing docker.io/library/nginx:1.25"
docker tag docker.io/library/nginx:1.25 destination.example.com/images/library/nginx:1.25

echo "Processing quay.io/coreos/etcd:v3.5.12"
docker tag quay.io/coreos/etcd:v3.5.12 destination.example.com/images/coreos/etcd:v3.5.12

echo "Processing source.example.com/team/app:2.1.0"
docker tag source.example.com/team/app:2.1.0 destination.example.com/images/team/app:2.1.0
```