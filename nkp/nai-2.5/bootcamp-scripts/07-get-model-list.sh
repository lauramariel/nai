#!/usr/bin/env bash
# Not for production use

# Get model list from catalog

set -euo pipefail
IFS=$'\n\t'

source ~/.secrets
source ~/.env

export CURL_OPTS="-sk"
export HEADERS="Content-Type: application/json"
export AUTH="admin:$NAI_NEW_ADMIN_PW"

echo -e "## Hugging Face Models"
curl $CURL_OPTS -X GET \
"$NAI_UI_ENDPOINT/api/enterpriseai/v1/catalogs" \
-H "$HEADERS" \
-u "$AUTH" | \
jq -r '.data.catalogs[] | select(.sourceHub=="HuggingFace").modelName'

echo -e "## NVIDIA Models"
curl $CURL_OPTS -X GET \
"$NAI_UI_ENDPOINT/api/enterpriseai/v1/catalogs" \
-H "$HEADERS" \
-u "$AUTH" | \
jq -r '.data.catalogs[] | select(.sourceHub=="NvidiaNIM").modelName'