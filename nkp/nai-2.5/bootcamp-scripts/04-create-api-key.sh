#!/usr/bin/env bash
# Not for production use

# Creates API key not attached to any endpoint

set -euo pipefail
# set -x
IFS=$'\n\t'

# Modify as needed
export API_KEY_PREFIX="llama"

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
  local auth
  auth=$(user_auth "$user")

  local userid
  userid=$(userid_from_username "$user")

  echo "Creating API key for $user"

  local payload
  payload=$(cat <<EOF
{
  "endpoints": [],
  "name": "$API_KEY_PREFIX-$userid"
}
EOF
)

  response=$(curl $CURL_OPTS -X POST \
    "$NAI_UI_ENDPOINT/api/enterpriseai/v1/apikeys" \
    -H "$HEADERS" \
    -u "$auth" \
    -d "$payload")

  api_key=$(echo ${response} | jq '.data.key')

  echo "export USER=$user"
  echo "export API_KEY=$api_key"
}



# Main function
main() {
  mapfile -t USERS < <(generate_user_list "$NO_OF_USERS")

  for user in "${USERS[@]}"; do
    create_api_key "$user"
  done
}

main "$@"