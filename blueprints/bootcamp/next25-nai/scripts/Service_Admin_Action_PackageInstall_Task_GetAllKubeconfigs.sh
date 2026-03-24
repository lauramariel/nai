#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Get all kubeconfigs for kubie to easily switch contexts with kubie ctx
kubectl get clusters -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' | xargs -n2 sh -c 'nkp get kubeconfig -c "$1" -n "$0" > ${HOME}/.kube/"$0_$1".yml'