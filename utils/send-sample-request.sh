#!/bin/bash
set -ex

export NAI_URL=""
export API_KEY=""
export NAI_EP=""
export PROMPT="Help me plan a trip to Paris."

# time curl -k -X 'POST' "https://$NAI_URL/api/v1/completions" -w '\nResponse Code: %{http_code}\n' -H 'accept: application/json' -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' -d "{
# \"max_tokens\": 4096,
# \"model\": \"$NAI_EP\",
# \"prompt\": \"Help me plan a trip to Paris.\"
# }"

# NAI 2.5
time curl -k -X 'POST' "https://$NAI_URL/enterpriseai/v1/chat/completions" -w '\nResponse Code: %{http_code}\n' -H 'accept: application/json' -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' -d "{
      \"model\": \"$NAI_EP\",
      \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"$PROMPT\"
        }
      ],
      \"max_tokens\": 4096,
      \"stream\": false
}"