#!/usr/bin/env bash
set -euo pipefail +H

export KEYCLOAK_URL=""
export KEYCLOAK_ADMIN_PW=""
export REALM_NAME=""
export USER_PASSWORD=""

# Create 50 users
for USER_ID in {0..50}; do
    echo "Creating user erag$USER_ID"

# Construct payload for creating user
PAYLOAD=$(cat <<EOF
{
"username": "erag$USER_ID",
"enabled": true,
"email": "erag$USER_ID@example.com",
"firstName": "erag$USER_ID",
"lastName": "admin",
"credentials": [{"type": "password", "value": "$USER_PASSWORD", "temporary": false}]
}
EOF
)
    # Get admin access token
    export TOKEN=$(curl -s -d "client_id=admin-cli" \
        -d "username=admin" \
        -d "password=$KEYCLOAK_ADMIN_PW" \
        -d "grant_type=password" \
        "https://$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" | jq -r .access_token)

    # Create user
    curl -s -X POST "https://$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD"

    # Get User UUID
    USER_UUID=$(curl -s -X GET "https://$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=erag$USER_ID" \
        -H "Authorization: Bearer $TOKEN" | jq -r .[].id)

    # Get Client IDS
    CLIENTS=$(curl -s -X GET "https://$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" -H "Authorization: Bearer $TOKEN")
    CLIENT_IDS=$(echo $CLIENTS | jq -r '.[] | select(.clientId == ("EnterpriseRAG-oidc-backend", "EnterpriseRAG-oidc-minio", "EnterpriseRAG-oidc")) | .id')


    for CLIENT_ID in $CLIENT_IDS
    do
        TARGET_ROLES_REGEX="ERAG-admin|consoleAdmin"

        echo "Checking client: $CLIENT_ID"

        # 1. Fetch roles and filter for ANY of our target names in one go
        # This creates the array format [{id: "...", name: "..."}] that Keycloak needs
        PAYLOAD=$(curl -s -X GET "https://$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_ID/roles" \
            -H "Authorization: Bearer $TOKEN" | \
            jq -c "[.[] | select(.name | test(\"^($TARGET_ROLES_REGEX)$\")) | {id: .id, name: .name}]")

        # 2. If the resulting array is not empty, POST it
        if [[ "$PAYLOAD" != "[]" && -n "$PAYLOAD" ]]; then
            echo "--> Found matching roles! Mapping to user $USER_UUID..."
            
            curl -s -X POST "https://$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$USER_UUID/role-mappings/clients/$CLIENT_ID" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        else
            echo "--> No matching roles found in this client."
        fi
    done

done