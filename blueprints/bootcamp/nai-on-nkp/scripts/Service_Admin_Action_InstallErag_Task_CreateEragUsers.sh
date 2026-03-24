#!/usr/bin/env bash
set -euo pipefail +H
#set -x

source ~/.env
export REALM_NAME="EnterpriseRAG"
export ERAG_USER_PASSWORD="$NUTANIX_PASSWORD" # desired user password

# Create 50 users
for USER_ID in $(seq 1 $NO_OF_USERS)
do
	echo "Creating user adminuser0$USER_ID"

# Construct payload for creating user
PAYLOAD=$(cat <<EOF
{
"username": "adminuser0$USER_ID",
"enabled": true,
"email": "adminuser0$USER_ID@example.com",
"firstName": "adminuser0$USER_ID",
"lastName": "admin",
"credentials": [{"type": "password", "value": "$ERAG_USER_PASSWORD", "temporary": false}]
}
EOF
)
    # Get admin access token
    export TOKEN=$(curl -s -d "client_id=admin-cli" \
        -d "username=admin" \
        -d "password=$KEYCLOAK_ADMIN_PW" \
        -d "grant_type=password" \
        "https://$KEYCLOAK_FQDN/realms/master/protocol/openid-connect/token" | jq -r .access_token)

    # Relax password policy just once
    if [[ "$USER_ID" == 1 ]]
    then
	echo "Setting password policy to 11 chars"
        curl -X PUT \
        "https://$KEYCLOAK_FQDN/admin/realms/$REALM_NAME" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{
                "passwordPolicy": "length(11) and digits(1) and upperCase(1) and lowerCase(1) and specialChars(1) and notUsername(undefined) and passwordHistory(5)"
            }'
    fi

    # Create user
    curl -s -X POST "https://$KEYCLOAK_FQDN/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD"

    # Get User UUID
    USER_UUID=$(curl -s -X GET "https://$KEYCLOAK_FQDN/admin/realms/$REALM_NAME/users?username=erag$USER_ID" \
        -H "Authorization: Bearer $TOKEN" | jq -r .[].id)

    # Get Client IDS
    CLIENTS=$(curl -s -X GET "https://$KEYCLOAK_FQDN/admin/realms/$REALM_NAME/clients" -H "Authorization: Bearer $TOKEN")
    CLIENT_IDS=$(echo $CLIENTS | jq -r '.[] | select(.clientId == ("EnterpriseRAG-oidc-backend", "EnterpriseRAG-oidc-minio", "EnterpriseRAG-oidc")) | .id')


    for CLIENT_ID in $CLIENT_IDS
    do
        TARGET_ROLES_REGEX="ERAG-admin|consoleAdmin"

        echo "Checking client: $CLIENT_ID"

        # 1. Fetch roles and filter for ANY of our target names in one go
        # This creates the array format [{id: "...", name: "..."}] that Keycloak needs
        PAYLOAD=$(curl -s -X GET "https://$KEYCLOAK_FQDN/admin/realms/$REALM_NAME/clients/$CLIENT_ID/roles" \
            -H "Authorization: Bearer $TOKEN" | \
            jq -c "[.[] | select(.name | test(\"^($TARGET_ROLES_REGEX)$\")) | {id: .id, name: .name}]")

        # 2. If the resulting array is not empty, POST it
        if [[ "$PAYLOAD" != "[]" && -n "$PAYLOAD" ]]; then
            echo "--> Found matching roles! Mapping to user $USER_UUID..."
            
            curl -s -X POST "https://$KEYCLOAK_FQDN/admin/realms/$REALM_NAME/users/$USER_UUID/role-mappings/clients/$CLIENT_ID" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        else
            echo "--> No matching roles found in this client."
        fi
    done

done