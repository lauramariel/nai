#!/bin/bash
set -x

cat vision_payload.json | envsubst | curl -X 'POST' "https://$NAI_URL/api/v1/chat/completions" \
 -H "Authorization: Bearer $NAI_KEY" \
 -H 'accept: application/json' \
 -H 'Content-Type: application/json' \
 -d @- | jq .choices[0].message.content
