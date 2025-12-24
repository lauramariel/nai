#!/usr/bin/env bash
# Not for production use

# Create API key to attach to existing endpoint
# TODO: Update to work without an endpoint to consolidate scripts

set -euo pipefail
#set -x
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

# Create API key fuction
create_api_key() {
  local user="$1"
  local endpoint="$2"
  local apikeyname="$3"

  endpoint_list=()
  # add endpoint to list as long as it's not empty
  if [[ -n $endpoint ]]; then
    endpoint_list+=("$endpoint")
  fi

  local auth
  auth=$(user_auth "$user")

  #echo "Creating API key $apikeyname for $user to attach to endpoint: $endpoint"

  local payload
  payload=$(jq -n \
  --arg name "$apikeyname" \
  --argjson endpoint_list "$(printf '%s\n' "${endpoint_list[@]}" | jq -R . | jq -s .)" \
  '{endpoints: $endpoint_list, name: $name}')

  response=$(curl $CURL_OPTS -X POST \
    "$NAI_UI_ENDPOINT/api/enterpriseai/v1/apikeys" \
    -H "$HEADERS" \
    -u "$auth" \
    -d "$payload"
  )
  #echo $payload
  #echo $response
  api_key=$(echo ${response} | jq '.data.key')

  echo "export API_KEY=$api_key"
  echo "export NAI_EP=$endpoint"
}

# Main function to create a new API key to attach to existing endpoint
main() {
  mapfile -t USERS < <(generate_user_list "$NO_OF_USERS")

  for user in "${USERS[@]}"; do
    userid=$(userid_from_username "$user")
    #endpoint="llama-$userid"
    #endpoint=""
    endpoint="gemma-$userid"
    apikeyname="gemma-$userid"
    create_api_key "$user" "$endpoint" "$apikeyname"
  done
}

main "$@"