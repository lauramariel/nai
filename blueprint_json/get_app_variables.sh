#!/usr/bin/env bash
# Get app variables from a blueprint
set -euo pipefail
IFS=$'\n\t'

TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <blueprint_json>"
    exit 1
else
    jq -r '.spec.resources.app_profile_list[].variable_list[] | [.name, .value] | @csv' $TARGET
fi