#!/usr/bin/env bash
# Not for production use

# Download specified model from HF URL

set -euo pipefail
set -x
IFS=$'\n\t'

# Modify as needed
#export MODEL_NAME="meta-llama/Llama-3.2-1B-Instruct"
export MODEL_NAME="google/gemma-3-270m-it"

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
generate_users() {
  local count="$1"
  local users=()

  for i in $(seq 1 "$count"); do
    users+=("adminuser$(printf "%02d" "$i")")
  done

  printf '%s\n' "${users[@]}"
}

# Model functions
download_model() {
  local user="$1"
  local auth
  auth=$(user_auth "$user")

  local userid
  userid=$(userid_from_username "$user")

  echo "Downloading model for $user"


  local payload
  payload=$(cat <<EOF
{
    "modelProvider": {
        "customModelDetails": {
            "developer": "",
            "modelCapabilities": [
                "text-to-text"
            ]
        }
    },
    "name": "gemma-3-270m-it-$userid",
    "sourceFormat": "hf",
    "storageProvider": {
        "huggingFaceHub": {
            "repoId": "$MODEL_NAME"
        }
    }
}
EOF
)

  curl $CURL_OPTS -X POST \
    "$NAI_UI_ENDPOINT/api/enterpriseai/v1/models" \
    -H "$HEADERS" \
    -u "$auth" \
    -d "$payload"
}

# Main function
main() {
  mapfile -t USERS < <(generate_users "$NO_OF_USERS")

  for user in "${USERS[@]}"; do
    download_model "$user"
  done
}

main "$@"