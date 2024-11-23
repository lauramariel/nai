#!/bin/bash

export API_KEY="e0a61171-b007-47ba-a1e9-138c3a8cfaba"
export NAI_URL="nim.nai-nim-rag.odin.cloudnative.nvdlab.net"
export ENDPOINT_NAME="nai-llama-3-8b-nim"


while :
do
time curl -k -X 'POST' "https://$NAI_URL/api/v1/completions" -H 'accept: application/json' -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' -d "{
\"max_tokens\": 200,
\"model\": \"$ENDPOINT_NAME\",
\"prompt\": \"Explain Deep Neural Networks in simple terms.\"
}"
sleep 5
done
