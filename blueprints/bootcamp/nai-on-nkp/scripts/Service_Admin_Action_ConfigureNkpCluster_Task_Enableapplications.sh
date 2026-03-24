#!/usr/bin/env bash
set -euo pipefail

source ~/.env

# Loop through each app and execute the command
for app in $MANAGEMENT_WORKSPACE_APPS; do
    appdeployment_name=$(echo "$app" | cut -d',' -f1)
    app_name=$(echo "$app" | cut -d',' -f2)

    # Execute the command
    echo "nkp create appdeployment $appdeployment_name --app $app_name -w kommander-workspace"
    nkp create appdeployment "$appdeployment_name" --app "$app_name" -w kommander-workspace
    sleep 1
done

