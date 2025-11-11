#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  labels:
    kommanderType: license
  name: nutanix-license
  namespace: kommander
stringData:
  nutanix-license-key: @@{NKP_LICENSE_KEY}@@
---
apiVersion: kommander.mesosphere.io/v1beta1
kind: License
metadata:
  name: nutanix-license
  namespace: kommander
spec:
  nutanixLicenseRef:
    name: nutanix-license
EOF