#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

kubectl --namespace metallb-system patch ipaddresspool metallb --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/addresses/-",
    "value": "'"${MGMT_LB_IP_RANGE_USERS_STARTS}-${MGMT_LB_IP_RANGE_USERS_ENDS}"'"
  }
]'


