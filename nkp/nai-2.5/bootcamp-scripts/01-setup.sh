#!/usr/bin/env bash
# Not for production use

# Set up new NAI instance for bootcamp

set -euo pipefail
IFS=$'\n\t'

source ~/.secrets
source ~/.env

export CURL_OPTS="-sk"
export HEADERS="Content-Type: application/json"
export DEFAULT_AUTH="admin:$NAI_DEFAULT_PW"
export NEW_AUTH="admin:$NAI_NEW_ADMIN_PW"

##### Reset password
echo -e "Resetting password"
PAYLOAD=$(cat <<EOF
{"username":"admin","old_password":"$NAI_DEFAULT_PW","new_password":"$NAI_NEW_ADMIN_PW"}
EOF
)
curl $CURL_OPTS -X PUT "$NAI_UI_ENDPOINT/api/iam/authn/v1/users/password" -H $HEADERS -u $DEFAULT_AUTH -d "$PAYLOAD"

# sleep 1

##### Accept EULA
echo -e "\nAccepting EULA"
PAYLOAD=$(cat <<EOF
{"eula":{"accepted":true,"name":"admin","company":"Nutanix"}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/cluster/config" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"

sleep 1

##### Enable Pulse
echo -e "\nEnabling Pulse"
PAYLOAD=$(cat <<EOF
{"pulse":{"accepted":true}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/cluster/config" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"

sleep 1

##### Add License
echo -e "\nAdding License"
PAYLOAD=$(cat <<EOF
{"licenses":[{"licenseKey":"$LICENSE_KEY","meterType":"GB","licenseClusterUUID":"$LICENSE_CLUSTER_UUID"}]}
EOF
)
curl $CURL_OPTS -X PUT "$NAI_UI_ENDPOINT/api/enterpriseai/v1/licenses" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"

##### Create HF Token
echo -e "\nCreating HF Token"
PAYLOAD=$(cat <<EOF
{"name":"hf_token","data":{"HF_TOKEN":"$HF_TOKEN"},"type":"hf"}
EOF
)
curl $CURL_OPTS -X POST "$NAI_UI_ENDPOINT/api/enterpriseai/v1/credentials" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"

##### Enable Manual Upload Option for Users
echo -e "\nEnable Manual Upload"
PAYLOAD=$(cat <<EOF
{"manualUpload":{"enabled":true}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/cluster/config" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"

##### Enable Direct Download Option for Users
echo -e "\nEnable Manual Upload"
PAYLOAD=$(cat <<EOF
{hfUrlImport: {enabled: true}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/cluster/config" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"

##### Enable meta-llama/Llama-3.2-1B-Instruct to be imported by users (required for bootcamp)
echo -e "\nEnable Import of meta-llama/Llama-3.2-1B-Instruct"

echo -e "\n"
echo -n "Getting catalog ID... "
# First, have to get catalog ID for the one we want
catalog_id=$(curl $CURL_OPTS -X GET "$NAI_UI_ENDPOINT/api/enterpriseai/v1/catalogs" -H $HEADERS -u $NEW_AUTH | jq -r '.data.catalogs[] | select(.modelName=="meta-llama/Llama-3.2-1B-Instruct").id')
echo -e $catalog_id

echo -e "\nEnabling catalog ID"
PAYLOAD=$(cat <<EOF
[{"catalogId":"$catalog_id","adminEnabled":true}]
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/catalogs" -H $HEADERS -u $NEW_AUTH -d "$PAYLOAD"