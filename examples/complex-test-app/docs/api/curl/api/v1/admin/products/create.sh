#!/usr/bin/env bash
set -euo pipefail

# Create Product
# POST /api/v1/admin/products
curl --request POST \
  --url "http://localhost:3000/api/v1/admin/products" \
  --header "X-Api-Key: {{api_key}}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
  "product": {
    "sku": "TEA-003",
    "name": "Jasmine",
    "category": "tea",
    "price_cents": 1400
  }
}'
