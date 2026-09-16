#!/usr/bin/env bash
set -euo pipefail

# Create Order
# POST /api/v1/orders
curl --request POST \
  --url "http://localhost:3000/api/v1/orders" \
  --header "Authorization: Bearer {{token}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "order": {
    "line_items": [
      {
        "sku": "TEA-001",
        "quantity": 2
      },
      {
        "sku": "MUG-001",
        "quantity": 1
      }
    ],
    "shipping_address": {
      "line1": "1 Analytical Engine Way",
      "city": "London",
      "country": "GB"
    }
  }
}'
