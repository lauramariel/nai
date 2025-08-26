#!/bin/bash
# Uses unsupported v1 APIs, do not use in production.
export NAI_DEFAULT_PW="@@{NAI_DEFAULT_PW}@@"
export NAI_NEW_ADMIN_PW="@@{NAI_NEW_ADMIN_PW}@@"
export NAI_NEW_USER_PW="@@{NAI_NEW_USER_PW}@@"
export HF_TOKEN="@@{HF_TOKEN}@@"
export NAI_UI_ENDPOINT="@@{NAI_UI_ENDPOINT}@@"
export CURL_OPTS="-sk"

USERS=()

# Create adminuser01-05
for i in {1..5}
do
  USERS+=("adminuser$(printf "%02d" $i)")
done

# Initial login to set token
echo -e "Initial login with default password to set JWT token"
PAYLOAD=$(cat <<EOF
{"username":"admin","password":"$NAI_DEFAULT_PW"}
EOF
)
JWT_TOKEN=$(curl "$CURL_OPTS" -X POST "$NAI_UI_ENDPOINT/api/v1/login/local" -H 'Content-Type: application/json' -d $PAYLOAD | jq -r .data.AccessToken)

sleep 1

# Reset password
echo -e "Resetting password"
PAYLOAD=$(cat <<EOF
{"currentPassword":"$NAI_DEFAULT_PW","newPassword":"$NAI_NEW_ADMIN_PW","username":"admin"}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/v1/users/reset_password" -H 'Content-Type: application/json'  -H "Authorization: $JWT_TOKEN" -d $PAYLOAD

sleep 1

# Accept EULA
echo -e "\nAccepting EULA"
PAYLOAD=$(cat <<EOF
{"eula":{"accepted":true,"name":"admin","company":"Nutanix"}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/v1/cluster/config" -H 'Content-Type: application/json'  -H "Authorization: $JWT_TOKEN" -d $PAYLOAD

sleep 1

# Enable Pulse
echo -e "\nEnabling Pulse"
PAYLOAD=$(cat <<EOF
{"pulse":{"accepted":true}}
EOF
)
curl $CURL_OPTS -X PATCH "$NAI_UI_ENDPOINT/api/v1/cluster/config" -H 'Content-Type: application/json'  -H "Authorization: $JWT_TOKEN" -d $PAYLOAD

sleep 1

# Create HF Token
echo -e "\nCreating HF Token"
PAYLOAD=$(cat <<EOF
{"name":"hf_token","data":{"HF_TOKEN":"$HF_TOKEN"},"type":"hf"}
EOF
)
curl $CURL_OPTS -X POST "$NAI_UI_ENDPOINT/api/v1/credentials" -H 'Content-Type: application/json'  -H "Authorization: $JWT_TOKEN" -d $PAYLOAD

sleep 1

echo -e "\nCreating users"
# Create 5 users
for USER_NAI_NAME in "${USERS[@]}"
do
PAYLOAD=$(cat <<EOF
{"email":"$USER_NAI_NAME@ntnxlab.local","password":"$NAI_NEW_USER_PW","firstName":"Bootcamp","lastName":"User$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z' | head -c 5)","username":"$USER_NAI_NAME","role":"MLUser"}
EOF
)
echo -e "\nCreating user $USER_NAI_NAME"
curl $CURL_OPTS -X POST "$NAI_UI_ENDPOINT/api/v1/users" -H 'Content-Type: application/json' -H "Authorization: $JWT_TOKEN" -d $PAYLOAD
sleep 1
done
