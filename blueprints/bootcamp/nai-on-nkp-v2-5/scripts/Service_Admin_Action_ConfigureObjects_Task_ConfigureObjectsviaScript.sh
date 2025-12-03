#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

# Download and run script

curl -fsSL "${OBJ_CONFIG_SCRIPT}" | python