#!/bin/bash

export API_KEY=""
export NAI_URL=""
export ENDPOINT_NAME=""
export PAYLOAD="{
      \"model\": \"$ENDPOINT_NAME\",
      \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"Explain Deep Neural Networks in simple terms\"
        }
      ],
      \"max_tokens\": 256,
      \"stream\": false
}"

while :
do
time curl -k -X 'POST' "https://$NAI_URL/api/v1/chat/completions" \
 -H "Authorization: Bearer $API_KEY" \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -d "$PAYLOAD"
sleep 5
done
