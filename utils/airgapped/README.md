This script pulls container images defined in images.txt, tags them, then pushes to the destination registry.

Images should be in images.txt

Usage:
```
bash generate-migration-script.sh <destination_registry> [--pull] [--tag] [--push] [--dest-path]
```

Example usage
```
bash generate-migration-script.sh harbor.example.com --dest-path bootcamps
```

Sample output:
```
Generated migrate-images.sh
Options: pull=true, tag=true, push=true, dest-path=bootcamps
```

Example generated script
```
#!/usr/bin/env bash
set -euo pipefail

docker login harbor.example.com

echo "Processing docker.io/library/nginx:1.25"
docker pull docker.io/library/nginx:1.25
docker tag docker.io/library/nginx:1.25 harbor.example.com/bootcamps/library/nginx:1.25
docker push harbor.example.com/bootcamps/library/nginx:1.25

echo "Processing quay.io/coreos/etcd:v3.5.12"
docker pull quay.io/coreos/etcd:v3.5.12
docker tag quay.io/coreos/etcd:v3.5.12 harbor.example.com/bootcamps/coreos/etcd:v3.5.12
docker push harbor.example.com/bootcamps/coreos/etcd:v3.5.12

echo "Processing registry.example.com/team/app:2.1.0"
docker pull registry.example.com/team/app:2.1.0
docker tag registry.example.com/team/app:2.1.0 harbor.example.com/bootcamps/team/app:2.1.0
docker push harbor.example.com/bootcamps/team/app:2.1.0
```

You can use the --pull, --push, and --tag options if you want a script that just contains those actions e.g.

```
bash generate-migration-script.sh harbor.example.com --dest-path bootcamps --tag
```

will produce a script that just contains

```
echo "Processing docker.io/library/nginx:1.25"
docker tag docker.io/library/nginx:1.25 harbor.example.com/bootcamps/library/nginx:1.25

echo "Processing quay.io/coreos/etcd:v3.5.12"
docker tag quay.io/coreos/etcd:v3.5.12 harbor.example.com/bootcamps/coreos/etcd:v3.5.12

echo "Processing registry.example.com/team/app:2.1.0"
docker tag registry.example.com/team/app:2.1.0 harbor.example.com/bootcamps/team/app:2.1.0
```