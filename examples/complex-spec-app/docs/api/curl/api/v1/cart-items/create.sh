#!/usr/bin/env bash
set -euo pipefail

# Create Cart Item
# POST /api/v1/cart/items
curl --request POST \
  --url "http://localhost:3000/api/v1/cart/items" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "item": {
    "sku": "TEA-002",
    "quantity": 3
  }
}'
