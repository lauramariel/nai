#!/bin/bash
set -ex

# export NAI_URL="10.28.131.191:30746"
# export API_KEY="3d34d8fa-64c2-4b76-9f46-018ba4eae59a"
# export NAI_EP="hiren-amx"

export NAI_URL="nai.tmelab.net"
export API_KEY="8cfbd98a-be81-44c8-9750-ca5c4844101c"
export NAI_EP="mistral"

# export NAI_URL="ai.nutanix.com"
# export API_KEY="4e2493cc-5251-4078-96e8-12d126eb62da"
# export NAI_EP="llama-1b-ep"

time curl -k -X 'POST' "https://$NAI_URL/api/v1/completions" -H 'accept: application/json' -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' -d "{
\"max_tokens\": 200,
\"model\": \"$NAI_EP\",
\"prompt\": \"Help me plan a trip to Paris.\"
}"
