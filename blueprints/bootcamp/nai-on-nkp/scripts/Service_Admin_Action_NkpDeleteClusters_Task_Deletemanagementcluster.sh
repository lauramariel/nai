#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

nkp delete cluster -c $CLUSTER_NAME --self-managed