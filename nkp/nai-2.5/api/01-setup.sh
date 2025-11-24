#!/bin/bash
# Uses unsupported v1 APIs, do not use in production.
export NAI_DEFAULT_PW="@@{NAI_DEFAULT_PW}@@"
export NAI_NEW_ADMIN_PW="@@{NAI_NEW_ADMIN_PW}@@"
export HF_TOKEN="@@{HF_TOKEN}@@"
export NAI_UI_ENDPOINT="@@{NAI_UI_ENDPOINT}@@"
export CURL_OPTS="-sk"
export LICENSE_KEY="@@{NAI_LICENSE_KEY}@@"
export LICENSE_CLUSTER_UUID="@@{NAI_LICENSE_UUID}@@"

##### Reset password
echo -e "Resetting password"
PAYLOAD=$(cat <<EOF
{"username":"admin","old_password":"$NAI_DEFAULT_PW","new_password":"$NAI_NEW_ADMIN_PW"}
EOF
)
curl $CURL_OPTS -X PUT "$NAI_UI_ENDPOINT/api/iam/authn/v1/users/password" -H 'Content-Type: application/json' -u "admin:$NAI_DEFAULT_PW" -d "$PAYLOAD"

# sleep 1

##### Accept EULA
echo -e "\nAccepting EULA"
PAYLOAD=$(cat <<EOF
{"eula":{"accepted":true,"name":"admin","company":"Nutanix"}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/cluster/config" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" -d "$PAYLOAD"

sleep 1

##### Enable Pulse
echo -e "\nEnabling Pulse"
PAYLOAD=$(cat <<EOF
{"pulse":{"accepted":true}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/enterpriseai/v1/cluster/config" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" -d "$PAYLOAD"

sleep 1

##### Add License
echo -e "\nAdding License"
PAYLOAD=$(cat <<EOF
{"licenses":[{"licenseKey":"UBFWCB-S2SEMW-9RUNV8-MSNLET-MCNFQB-Z2Q5SA","meterType":"GB","licenseClusterUUID":"c330f50b-bd28-49bc-acde-ba8892865426"}]}
EOF
)
curl $CURL_OPTS -X PUT "$NAI_UI_ENDPOINT/api/enterpriseai/v1/licenses" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" -d "$PAYLOAD"

##### Create HF Token
echo -e "\nCreating HF Token"
PAYLOAD=$(cat <<EOF
{"name":"hf_token","data":{"HF_TOKEN":"$HF_TOKEN"},"type":"hf"}
EOF
)
curl $CURL_OPTS -X POST "$NAI_UI_ENDPOINT/api/enterpriseai/v1/credentials" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" -d "$PAYLOAD"