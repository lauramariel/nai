#!/bin/bash

set -e

kubectl -n kommander delete appdeployment ai-navigator-app

kubectl patch deployment kommander-kommander-ui \
  -n kommander \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "4"},
       {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "4Gi"}]'

NKP_DASHBOARD_URL=$(kubectl -n kommander get svc kommander-traefik -o go-template='https://{{with index .status.loadBalancer.ingress 0}}{{or .hostname .ip}}{{end}}/dkp/kommander/dashboard{{ "\n"}}')
NKP_DASHBOARD_USERNAME=$(kubectl -n kommander get secret dkp-credentials -o go-template='{{.data.username|base64decode}}')
NKP_DASHBOARD_PASSWORD=$(kubectl -n kommander get secret dkp-credentials -o go-template='{{.data.password|base64decode}}')

cat <<EOF >>~/.env
export NKP_DASHBOARD_URL=${NKP_DASHBOARD_URL}
export NKP_DASHBOARD_USERNAME=${NKP_DASHBOARD_USERNAME}
export NKP_DASHBOARD_PASSWORD=${NKP_DASHBOARD_PASSWORD}
EOF

echo "NKP_DASHBOARD_URL=${NKP_DASHBOARD_URL}"
echo "NKP_DASHBOARD_USERNAME=${NKP_DASHBOARD_USERNAME}"
echo "NKP_DASHBOARD_PASSWORD=${NKP_DASHBOARD_PASSWORD}"