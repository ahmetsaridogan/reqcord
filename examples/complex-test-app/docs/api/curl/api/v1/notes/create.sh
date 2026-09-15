#!/usr/bin/env bash
set -euo pipefail

# Create Note
# POST /api/v1/orders/:order_id/notes
curl --request POST \
  --url "http://localhost:3000/api/v1/orders/1/notes" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "note": {
    "body": "Ring the bell twice"
  }
}'
