#!/usr/bin/env bash
# Not for production use

# Create users for bootcamp

set -euo pipefail
IFS=$'\n\t'

source ~/.secrets
source ~/.env

export CURL_OPTS="-sk"

USERS=()

# Create NAI users
for i in $(seq 1 $NO_OF_USERS)
do
  USERS+=("adminuser$(printf "%02d" $i)")
done

echo -e "\nCreating users and adding to auth policy"
# Get auth policy UUID that matches ML User_acp
ENDPOINT="api/iam/v4.1.b1/authz/authorization-policies?%24filter=displayName%20eq%20%27ML%20User_acp%27"
ACP_UUID=$(curl $CURL_OPTS -X GET "$NAI_UI_ENDPOINT/$ENDPOINT" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" | jq .data[].extId)

# Get the role UUID for ML User
ENDPOINT="api/iam/v4.1.b1/authz/roles?%24filter=displayName%20eq%20%27ML%20User%27"
ROLE_UUID=$(curl $CURL_OPTS -X GET "$NAI_UI_ENDPOINT/$ENDPOINT" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" | jq .data[].extId)


# Create 5 users
for USER_NAI_NAME in "${USERS[@]}"
do
PAYLOAD=$(cat <<EOF
{"username":"$USER_NAI_NAME","password":"$NAI_NEW_USER_PW","firstName":"Bootcamp","lastName":"User$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z' | head -c 5)","status":"ACTIVE","isForceResetPasswordEnabled":false,"userType":"LOCAL"}
EOF
)
echo -e "\nCreating user $USER_NAI_NAME"
USER_UUID=$(curl $CURL_OPTS -X POST "$NAI_UI_ENDPOINT/api/iam/v4.1.b1/authn/users" -H 'Content-Type: application/json' -u "admin:$NAI_NEW_ADMIN_PW" -d "$PAYLOAD" | jq .data.extId )

echo -e "\nAdd user to auth policy"

# Add user to auth policy

# Get existing users in auth policy. If this is adminuser01 then there are no users yet, so skip this part 
if [ "$USER_NAI_NAME" != "adminuser01" ]; then
    ENDPOINT="api/iam/v4.1.b1/authz/authorization-policies/${ACP_UUID//\"/}"
    values=$(curl ${CURL_OPTS} -X GET "$NAI_UI_ENDPOINT/$ENDPOINT" -u "admin:$NAI_NEW_ADMIN_PW" | jq .data.identities[].identityFilter.user.uuid.anyof[])
    # store in array
    existing_users=($values)
    USER_UUID_LIST=$(printf '%s,' "${existing_users[@]}")
    # add new user to the list
    USER_UUID_LIST="${USER_UUID_LIST}${USER_UUID}"
else
    USER_UUID_LIST="${USER_UUID}"
fi

# Construct payload
PAYLOAD=$(cat << EOF
{
"entities": [
    {
    "\$reserved": {
        "*": {
        "*": {
            "eq": "*"
        }
        }
    }
    }
],
"displayName": "ML User_acp",
"role": $ROLE_UUID,
"identities": [
    {
    "\$reserved": {
        "user": {
        "uuid": {
            "anyof": [
            $USER_UUID_LIST
            ]
        }
        }
    }
    }
],
"extId": $ACP_UUID,
"description": ""
}
EOF
)

# Get the etag for the auth policy
ENDPOINT="api/iam/v4.1.b1/authz/authorization-policies/${ACP_UUID//\"/}"
etag=$(curl ${CURL_OPTS}I -X GET "$NAI_UI_ENDPOINT/$ENDPOINT" -u "admin:$NAI_NEW_ADMIN_PW" | awk '/^etag:/ { print $2 }' | tr -d '\r')

# Add user to auth policy
curl $CURL_OPTS -X PUT "$NAI_UI_ENDPOINT/$ENDPOINT" -H 'Content-Type: application/json' -H "If-Match: $etag" -u "admin:$NAI_NEW_ADMIN_PW" -d "$PAYLOAD"

sleep 1

echo -e "\nCreating HF Token for user $USER_NAI_NAME"
PAYLOAD=$(cat <<EOF
{"name":"hf_token","data":{"HF_TOKEN":"$HF_TOKEN"},"type":"hf"}
EOF
)
curl $CURL_OPTS -X POST "$NAI_UI_ENDPOINT/api/enterpriseai/v1/credentials" -H 'Content-Type: application/json' -u "$USER_NAI_NAME:$NAI_NEW_USER_PW" -d "$PAYLOAD"
sleep 1

done