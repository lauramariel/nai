#!/usr/bin/env bash
# Not for production use

# Create Endpoint (requires Model to be created)

set -euo pipefail
set -x
IFS=$'\n\t'

# Environment / Config
source ~/.secrets
source ~/.env

export CURL_OPTS="-sk"
export HEADERS="Content-Type: application/json"

# Helpers
userid_from_username() {
  echo "$1" | tr -dc '0-9'
}

user_auth() {
  local user="$1"
  echo "$user:$NAI_NEW_USER_PW"
}

# User list generation
generate_user_list() {
  local count="$1"
  local users=()

  for i in $(seq 1 "$count"); do
    users+=("adminuser$(printf "%02d" "$i")")
  done

  printf '%s\n' "${users[@]}"
}

# Endpoint functions
search_model_id() {
  local auth="$1"
  local model_name="$2"

  local payload
  payload=$(cat <<EOF
{
  "offset": 0,
  "limit": 20,
  "filters": [],
  "sort": [
    {"field": "updated_at", "order": "DESCENDING"}
  ]
}
EOF
)

  curl $CURL_OPTS -X POST \
    "$NAI_UI_ENDPOINT/api/enterpriseai/v1/models/search" \
    -H "$HEADERS" \
    -u "$auth" \
    -d "$payload" |
    jq -r \
      --arg NAME "$model_name" \
      '.data.models[] | select(.name==$NAME).id'
}

search_apikey_id() {
  local auth="$1"
  local apikey_name="$2"

  local payload
  payload=$(cat <<EOF
{
  "offset": 0,
  "limit": 20,
  "filters": [],
  "sort": [
    {"field": "updated_at", "order": "DESCENDING"}
  ]
}
EOF
)

  curl $CURL_OPTS -X POST \
    "$NAI_UI_ENDPOINT/api/enterpriseai/v1/apikeys/search" \
    -H "$HEADERS" \
    -u "$auth" \
    -d "$payload" |
    jq -r \
      --arg NAME "$apikey_name" \
      '.data.apikeys[] | select(.name==$NAME).id'
}

# Main function for creating endpoint
# Depends on Model ID and API key ID in specified format
create_endpoint() {
  local user="$1"
  local auth
  auth=$(user_auth "$user")

  local userid
  userid=$(userid_from_username "$user")

  echo "Creating endpoint for $user"

  local model_id
  model_id=$(search_model_id "$auth" "llama32-1b$userid")

  local apikey_id
  apikey_id=$(search_apikey_id "$auth" "apikey$userid")

  local payload
  payload=$(cat <<EOF
{
  "cpu": 8,
  "platform": "intel-amx-cpu",
  "memoryInGi": 12,
  "maxInstances": 1,
  "minInstances": 1,
  "modelId": "$model_id",
  "apiKeys": [
    "$apikey_id"
  ],
  "name": "llama-$userid",
  "description": "",
  "acceleratorCount": 0,
  "engine": "vllm",
  "advancedConfig": {
    "vllmArgs": {
      "maxNumTokens": 4096
    }
  }
}
EOF
)

  curl $CURL_OPTS -X POST \
    "$NAI_UI_ENDPOINT/api/enterpriseai/v1/endpoints" \
    -H "$HEADERS" \
    -u "$auth" \
    -d "$payload"
}

# Main function
# Creates API key
# Creates endpoint using model and API key
# Requires model downloaded called "llama32-1b$userid"
main() {
  mapfile -t USERS < <(generate_user_list "$NO_OF_USERS")

  for user in "${USERS[@]}"; do
    create_endpoint "$user"
  done
}

main "$@"