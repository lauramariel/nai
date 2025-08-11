set -ex

NAI_UI_ENDPOINT="$1"

# Patch catalog item in NKP with the endpoint URL
kubectl patch cm nai-ui -n ${NKP_NAMESPACE} -p '{"data":{"dashboardLink":"'${NAI_UI_ENDPOINT}'"}}'
