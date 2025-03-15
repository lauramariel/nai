#!/bin/bash
set -ex

curl -k -X 'POST' "https://$NAI_URL/api/v1/completions" -H 'accept: application/json' -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' -d "{
\"max_tokens: 200,
\"model\": \"$NAI_EP\",
\"prompt\": \"Explain Deep Neural Networks in simple terms.\"
}"
