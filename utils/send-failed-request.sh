#!/bin/bash
set -ex

export API_KEY="e0a61171-b007-47ba-a1e9-138c3a8cfaba"
export NAI_URL="nim.nai-nim-rag.odin.cloudnative.nvdlab.net"
export ENDPOINT_NAME="nai-llama-3-8b-nim"


#export API_KEY="1edc1f85-c974-4bf0-9edb-346ef2f19f0f"
#export NAI_URL="www.ai.nutanix.com"
#export ENDPOINT_NAME="nim-llama3-1"

# Set unreasonable amount of max tokens for a failure scenario
curl -k -X 'POST' "https://$NAI_URL/api/v1/completions" -H 'accept: application/json' -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' -d "{
\"max_tokens\": 5000000,
\"model\": \"$ENDPOINT_NAME\",
\"prompt\": \"Explain Deep Neural Networks in simple terms.\"
}"
