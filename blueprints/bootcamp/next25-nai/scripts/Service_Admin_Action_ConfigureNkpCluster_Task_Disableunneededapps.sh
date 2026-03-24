#!/usr/bin/env bash
set -euo pipefail

source ~/.env

NS=kommander
NAME=ai-navigator-app
KIND=appdeployment

echo "Waiting for $KIND/$NAME to be created in namespace $NS..."

# Wait until the resource exists
until kubectl -n "$NS" get "$KIND" "$NAME" >/dev/null 2>&1; do
  sleep 5
done

echo "$KIND/$NAME found, deleting..."
kubectl -n "$NS" delete "$KIND" "$NAME"